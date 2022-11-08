def calc_n50(sequences):
    return 0  # ToDo


def count_bases(sequences):
    return {
        'count_a': [seq.count('A') for seq in sequences].sum(),
        'count_t': [seq.count('T') for seq in sequences].sum(),
        'count_g': [seq.count('G') for seq in sequences].sum(),
        'count_c': [seq.count('C') for seq in sequences].sum(),
        'count_n': [seq.count('N') for seq in sequences].sum(),
    }


def calc_GC(sequences):
    count_G = [seq.count('G') for seq in sequences].sum()
    count_C = [seq.count('C') for seq in sequences].sum()
    genome_size = [len(seq) for seq in sequences].sum()
    return (count_G + count_C) / genome_size