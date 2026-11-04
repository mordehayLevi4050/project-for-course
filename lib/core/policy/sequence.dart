/// MAX + 1 of [seqs], or 1 when there are none (AD-9). The one rule behind
/// every per-Group or global sequence number (`groupSeq`, `memberSeq`,
/// `saveSeq`): assigned once, inside the insert transaction.
int maxPlusOne(Iterable<int> seqs) =>
    seqs.isEmpty ? 1 : seqs.reduce((a, b) => a > b ? a : b) + 1;
