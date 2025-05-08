// buildMerkle.ts
// Usage: npx ts-node buildMerkle.ts

import fs from "fs";
import { buildPoseidon } from "circomlibjs";
import { MerkleTree }   from "merkletreejs";
import { keccak256 }    from "js-sha3";

/**
 * Canonicalize JSON per RFC8785: lexicographically sorted keys, no whitespace
 */
function canonicalize(x: any): string {
  if (x === null || typeof x !== "object") return JSON.stringify(x);
  if (Array.isArray(x)) return "[" + x.map(canonicalize).join(",") + "]";
  const keys = Object.keys(x).sort();
  return "{" + keys.map(k => JSON.stringify(k) + ":" + canonicalize(x[k])).join(",") + "}";
}

async function main() {
  // 1) Load your PAIN JSON
  const raw = JSON.parse(fs.readFileSync("./scripts/data/sample_usd_small.json", "utf8"));

  // 2) Extract relevant parts
  const senderObj    = raw.PmtInf.Dbtr;
  const recipientObj = raw.PmtInf.CdtTrfTxInf[0].Cdtr;
  const amountStr    = raw.PmtInf.CdtTrfTxInf[0].InstdAmt.Value; // e.g. "1234.56"
  const currencyStr  = raw.PmtInf.CdtTrfTxInf[0].InstdAmt.Ccy;   // e.g. "SGD"
  const expiryStr    = raw.PmtInf.ReqdExctnDt;                   // e.g. "2025-04-29"

  // 3) Define each field with its tag and raw data
  type FieldDef = { tag: bigint; canonical?: string; numericStr?: string; dateStr?: string };
  const fields: FieldDef[] = [
    { tag: 1n, canonical: canonicalize(senderObj)      },
    { tag: 2n, canonical: canonicalize(recipientObj)   },
    { tag: 3n, numericStr: amountStr                    },
    { tag: 4n, canonical: JSON.stringify(currencyStr)  },
    { tag: 5n, dateStr:    expiryStr                    },
  ];

  // 4) Initialize Poseidon
  const poseidon = await buildPoseidon();
  const F = poseidon.F;

  // Arrays to gather results
  const fieldValues: bigint[] = [];
  const leaves: Buffer[]      = [];
  const leavesBig: bigint[]   = []; // raw Poseidon leaf values
  const proofSiblings: string[][] = [];
  const proofDirs: number[][] = [];

  // 5) Compute each field's preimage and leaf buffer
  for (const field of fields) {
    let preimage: bigint;
    if (field.canonical != null) {
      // hashed snippet
      const hashHex = keccak256(field.canonical);
      preimage = BigInt("0x" + hashHex);
    } else if (field.numericStr != null) {
      // parse decimal string to integer (dropping dot)
      const [intPart, fracPart = ""] = field.numericStr.split(".");
      const combined = intPart + fracPart; // e.g. "1234"+"56" => "123456"
      preimage = BigInt(combined);
    } else if (field.dateStr != null) {
      // convert YYYY-MM-DD to YYYYMMDD integer
      preimage = BigInt(field.dateStr.replace(/-/g, ""));
    } else {
      throw new Error("Invalid field definition");
    }
    fieldValues.push(preimage);

    // Poseidon leaf: [preimage, tag]
    const leafFe = poseidon([F.e(preimage), F.e(field.tag)]);
    const leafBig = F.toObject(leafFe);
    const hex = leafBig.toString(16).padStart(64, "0");
    leaves.push(Buffer.from(hex, "hex"));
  }

  // 6) Build Poseidon Merkle tree (depth=4 → 16 slots)
  const hashFn = (L: Buffer, R?: Buffer) => {
    const rightBuf = R ?? L;
    const l = BigInt("0x" + L.toString("hex"));
    const r = BigInt("0x" + rightBuf.toString("hex"));
    const h = poseidon([F.e(l), F.e(r)]);
    const big = F.toObject(h);
    const hex = big.toString(16).padStart(64, "0");
    return Buffer.from(hex, "hex");
  };
  const tree = new MerkleTree(leaves, hashFn, { hashLeaves: false, sort: false, duplicateOdd: true });

  // 7) Generate proofs
  for (const leafBuf of leaves) {
    const proof = tree.getProof(leafBuf);
    proofSiblings.push(proof.map(p => BigInt("0x" + p.data.toString("hex")).toString()));
    proofDirs.push(proof.map(p => (p.position === "right" ? 1 : 0)));
  }

  // 7.1) Normalize proofs to match circuit DEPTH
  const DEPTH = 3;
  for (let i = 0; i < proofSiblings.length; i++) {
    let sibs = proofSiblings[i];
    let dirs = proofDirs[i];
    // Trim extra values if proof is deeper than DEPTH
    if (sibs.length > DEPTH) {
      sibs = sibs.slice(0, DEPTH);
      dirs = dirs.slice(0, DEPTH);
    }
    // Pad with last sibling/dir=0 until length == DEPTH
    while (sibs.length < DEPTH) {
      const last = sibs[sibs.length - 1] || sibs[0];
      sibs.push(last);
      dirs.push(0);
    }
    proofSiblings[i] = sibs;
    proofDirs[i] = dirs;
  }

  // 8) Assemble input.json
  const input = {
    root:             BigInt("0x" + tree.getRoot().toString("hex")).toString(),
    senderHash:       fieldValues[0].toString(),
    recipientHash:    fieldValues[1].toString(),
    minAmt:           "0",
    maxAmt:           "999999999999",
    currencyHash:     fieldValues[3].toString(),
    expTs:            fieldValues[4].toString(),

    senderPath:       proofSiblings[0],
    senderDirs:       proofDirs[0],
    recipientPath:    proofSiblings[1],
    recipientDirs:    proofDirs[1],

    amtPath:          proofSiblings[2],
    amtDirs:          proofDirs[2],
    amountVal:        fieldValues[2].toString(),

    ccyPath:          proofSiblings[3],
    ccyDirs:          proofDirs[3],
    currencyValHash:  fieldValues[3].toString(),

    expPath:          proofSiblings[4],
    expDirs:          proofDirs[4],
    expiryVal:        fieldValues[4].toString(),
  };

  // 9) Write input.json
  fs.writeFileSync("circuits/inputs/input.json", JSON.stringify(input, null, 2));
  console.log("✅ Generated circuits/inputs/input.json");
}

main().catch(console.error);
