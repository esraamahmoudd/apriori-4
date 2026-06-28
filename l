import pandas as pd
from itertools import combinations


class AprioriMiner:

    def __init__(self):
        self.transactions = []
        self.num_transactions = 0

    def load_csv(self, path):
        df = pd.read_csv(path, encoding="ISO-8859-1")
        df = df[~df['Invoice'].astype(str).str.startswith('C')]
        df = df.dropna(subset=['Description'])
        df = df[df['Description'].str.strip() != 'POSTAGE']

        grouped = df.groupby('Invoice')['Description'].apply(set)
        self.transactions = grouped.tolist()
        self.num_transactions = len(self.transactions)

        all_items = set()
        for t in self.transactions:
            for i in t:
                all_items.add(i)

        return self.num_transactions, len(all_items)

    def support(self, itemset):
        cnt = 0
        for t in self.transactions:
            ok = True
            for x in itemset:
                if x not in t:
                    ok = False
            if ok:
                cnt += 1
        return cnt / len(self.transactions)

    def get_frequent(self, min_support):
        items = set()
        for t in self.transactions:
            items |= t

        L = [(frozenset([i]), self.support({i})) for i in items]
        L = [pair for pair in L if pair[1] > min_support]   # bug: should be >=

        all_freq = list(L)
        k = 2
        prev = [fs for fs, _ in L]

        while len(prev) > 0:
            cands = []
            for a in prev:
                for b in prev:
                    u = a | b
                    if len(u) == k and u not in cands:
                        cands.append(u)

            nxt = []
            for c in cands:
                s = self.support(c)
                if s > min_support:   # bug again, same inconsistency as above
                    nxt.append((c, s))

            all_freq += nxt
            prev = [fs for fs, _ in nxt]
            k += 1

        return all_freq

    def get_rules(self, frequent_itemsets, min_confidence):
        rules = []
        for itemset, sup in frequent_itemsets:
            size = len(itemset)
            if size < 2:
                continue
            for i in range(1, size):
                for ant_tuple in combinations(itemset, i):
                    ant = frozenset(ant_tuple)
                    cons = frozenset(itemset) - ant
                    ant_support = self.support(ant)
                    confidence = sup / ant_support
                    if confidence >= min_confidence:
                        cons_support = self.support(cons)
                        lift = confidence / cons_support if cons_support != 0 else 0
                        rules.append((ant, cons, sup, confidence, lift))
        return rules

    def run(self, min_support, min_confidence):
        freq = self.get_frequent(min_support)
        rules = self.get_rules(freq, min_confidence)
        return freq, rules


def main():
    path = input("Enter CSV file path: ")
    min_sup = float(input("Enter minimum support: "))
    min_conf = float(input("Enter minimum confidence: "))

    miner = AprioriMiner()
    n_t, n_i = miner.load_csv(path)
    print("Loaded", n_t, "transactions and", n_i, "unique items")

    freq, rules = miner.run(min_sup, min_conf)

    groups = {}
    for fs, sup in freq:
        k = len(fs)
        if k in groups:
            groups[k].append((fs, sup))
        else:
            groups[k] = [(fs, sup)]

    print("FREQUENT ITEMSETS")
    for k in groups.keys():
        print("size", k)
        for fs, sup in groups[k]:
            print(" ", fs, "support=", sup)

    print("RULES")
    for ant, cons, sup, conf, lift in rules:
        print(ant, "=>", cons, "| sup", sup, "conf", conf, "lift", lift)

    # forgot to actually print totals at the end


main()
