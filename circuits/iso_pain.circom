pragma circom 2.1.6;

// ───── IMPORTS ─────
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/@zk-kit/binary-merkle-root.circom/src/binary-merkle-root.circom";

/*************************************************
 *  IsoPain v0.4 Production Grade                *
 *  - Full Merkle inclusion proofs with dynamic  *
 *    depth support                              *
 *  - Domain-separated Poseidon leaf hashing     *
 *  - Policy checks on amount, currency, expiry  *
 *************************************************/

template IsoPain(DEPTH) {
    // ───── PUBLIC INPUTS ─────
    signal input root;             // Merkle root
    signal input senderHash;       // hashed sender identifier
    signal input recipientHash;    // hashed recipient identifier
    signal input minAmt;           // policy minimum amount
    signal input maxAmt;           // policy maximum amount
    signal input currencyHash;     // expected currency hash
    signal input expTs;            // expected expiry timestamp

    // ───── MERKLE PROOF INPUTS ─────
    signal input senderPath[DEPTH];
    signal input senderDirs[DEPTH];
    signal input recipientPath[DEPTH];
    signal input recipientDirs[DEPTH];
    signal input amtPath[DEPTH];
    signal input amtDirs[DEPTH];
    signal input ccyPath[DEPTH];
    signal input ccyDirs[DEPTH];
    signal input expPath[DEPTH];
    signal input expDirs[DEPTH];

    // ───── PRIVATE VALUES ─────
    signal input amountVal;        // actual amount value from JSON
    signal input currencyValHash;  // actual currency hash from JSON
    signal input expiryVal;        // actual expiry from JSON

    // ───── LEAF HASHING WITH DOMAIN SEPARATION ─────
    component leafSender    = Poseidon(2);
    component leafRecipient = Poseidon(2);
    component leafAmount    = Poseidon(2);
    component leafCurrency  = Poseidon(2);
    component leafExpiry    = Poseidon(2);

    // tags: 1=sender,2=recipient,3=amount,4=currency,5=expiry
    leafSender.inputs[0]    <== senderHash;
    leafSender.inputs[1]    <== 1;
    signal senderLeaf      <== leafSender.out;

    leafRecipient.inputs[0] <== recipientHash;
    leafRecipient.inputs[1] <== 2;
    signal recipientLeaf   <== leafRecipient.out;

    leafAmount.inputs[0]    <== amountVal;
    leafAmount.inputs[1]    <== 3;
    signal amountLeaf      <== leafAmount.out;

    leafCurrency.inputs[0]  <== currencyValHash;
    leafCurrency.inputs[1]  <== 4;
    signal currencyLeaf    <== leafCurrency.out;

    leafExpiry.inputs[0]    <== expiryVal;
    leafExpiry.inputs[1]    <== 5;
    signal expiryLeaf      <== leafExpiry.out;

    // ───── MERKLE INCLUSION PROOFS ─────
    component mpSender    = BinaryMerkleRoot(DEPTH);
    component mpRecipient = BinaryMerkleRoot(DEPTH);
    component mpAmount    = BinaryMerkleRoot(DEPTH);
    component mpCcy       = BinaryMerkleRoot(DEPTH);
    component mpExp       = BinaryMerkleRoot(DEPTH);

    // wire depth, leaf, and proof arrays
    mpSender.depth     <== DEPTH;
    mpSender.leaf      <== senderLeaf;
    mpSender.indices   <== senderDirs;
    mpSender.siblings  <== senderPath;
    mpSender.out      === root;

    mpRecipient.depth    <== DEPTH;
    mpRecipient.leaf     <== recipientLeaf;
    mpRecipient.indices  <== recipientDirs;
    mpRecipient.siblings <== recipientPath;
    mpRecipient.out     === root;

    mpAmount.depth    <== DEPTH;
    mpAmount.leaf     <== amountLeaf;
    mpAmount.indices  <== amtDirs;
    mpAmount.siblings <== amtPath;
    mpAmount.out     === root;

    mpCcy.depth      <== DEPTH;
    mpCcy.leaf       <== currencyLeaf;
    mpCcy.indices    <== ccyDirs;
    mpCcy.siblings   <== ccyPath;
    mpCcy.out       === root;

    mpExp.depth      <== DEPTH;
    mpExp.leaf       <== expiryLeaf;
    mpExp.indices    <== expDirs;
    mpExp.siblings   <== expPath;
    mpExp.out       === root;

    // ───── POLICY CHECKS ─────
    component geMin    = GreaterEqThan(64);
    component leMax    = LessEqThan(64);
    component minLEmax = LessEqThan(64);

    geMin.in[0]    <== amountVal;
    geMin.in[1]    <== minAmt;
    geMin.out     === 1;

    leMax.in[0]    <== amountVal;
    leMax.in[1]    <== maxAmt;
    leMax.out     === 1;

    minLEmax.in[0] <== minAmt;
    minLEmax.in[1] <== maxAmt;
    minLEmax.out === 1;

    // equality assertions
    currencyValHash === currencyHash;
    expiryVal       === expTs;
}

// ───── MAIN ─────
component main { public [ root, senderHash, recipientHash, minAmt, maxAmt, currencyHash, expTs ] } = IsoPain(3);
