import subprocess
import numpy as np
from collections import Counter
import matplotlib.pyplot as plt
import math
import itertools
import random
import string

class CryptoAnalyzer:
    def __init__(self, bash_script_path):
        self.bash_script_path = bash_script_path
        self.original_words = [
            "ribbon", "slight", "frog", "oxygen", "range",
            "slam", "destroy", "dune", "fossil", "slow",
            "decrease", "primary", "hint", "loan", "limb",
            "palm", "act", "reward", "foot", "deposit",
            "response", "fashion", "under", "sail"
        ]

    def generate_passwords(self, num_passwords=1000):
        """Genera una variedad de contraseñas"""
        passwords = set()

        # Estrategias de generación de contraseñas
        strategies = [
            # Contraseñas aleatorias simples
            lambda: ''.join(random.choices(string.ascii_letters + string.digits, k=random.randint(6, 12))),

            # Contraseñas con símbolos especiales
            lambda: ''.join(random.choices(string.ascii_letters + string.digits + string.punctuation, k=random.randint(8, 14))),

            # Frases con espacios y mayúsculas
            lambda: ' '.join([
                ''.join(random.choices(string.ascii_lowercase, k=random.randint(3, 7)))
                for _ in range(random.randint(2, 4))
            ]).title(),

            # Palabras con números y símbolos
            lambda: f"{''.join(random.choices(string.ascii_lowercase, k=random.randint(4, 8)))}{random.randint(10, 999)}!",

            # Combinaciones de palabras en inglés
            lambda: random.choice([
                "password", "secret", "secure", "access", "admin", "login"
            ]) + str(random.randint(1, 100)) + random.choice(["!", "@", "#", "$"])
        ]

        # Generar contraseñas únicas
        while len(passwords) < num_passwords:
            strategy = random.choice(strategies)
            password = strategy()
            passwords.add(password)

        return list(passwords)

    def run_cipher(self, password, words=None):
        """Ejecuta el script de cifrado con una contraseña específica"""
        if words is None:
            words = self.original_words

        cmd = [self.bash_script_path, "-p", password] + words
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout.strip().split()

    def analyze_repetition(self, passwords):
        """Analiza patrones de repetición entre diferentes contraseñas"""
        results = {pw: self.run_cipher(pw) for pw in passwords}

        # Matriz de co-ocurrencia
        words = set(sum(results.values(), []))
        co_occurrence = {word: {pw: results[pw].count(word) for pw in passwords}
                         for word in words}

        return co_occurrence

    def calculate_entropy(self, passwords):
        """Calcula la entropía de las distribuciones de palabras"""
        results = {pw: self.run_cipher(pw) for pw in passwords}

        entropies = {}
        for pw, ciphered_words in results.items():
            word_counts = Counter(ciphered_words)
            total_words = len(ciphered_words)
            entropy = -sum((count/total_words) * math.log2(count/total_words)
                           for count in word_counts.values())
            entropies[pw] = entropy

        return entropies

    def similarity_analysis(self, passwords):
        """Analiza la similitud entre transformaciones con contraseñas similares"""
        results = {pw: set(self.run_cipher(pw)) for pw in passwords}

        similarities = {}
        for (pw1, res1), (pw2, res2) in itertools.combinations(results.items(), 2):
            intersection = len(res1.intersection(res2))
            total_unique = len(res1.union(res2))
            similarities[(pw1, pw2)] = intersection / total_unique

        return similarities

    def visualize_results(self, entropies, similarities):
        """Genera visualizaciones de los resultados"""
        # Gráfico de entropía
        plt.figure(figsize=(15, 6))
        entropy_values = list(entropies.values())
        plt.hist(entropy_values, bins=30, edgecolor='black')
        plt.title('Entropy Distribution of Transformations')
        plt.xlabel('Entropy')
        plt.ylabel('Frecuency')
        plt.tight_layout()
        plt.savefig('entropy_distribution.png')
        plt.close()

        # Análisis de similitudes
        sim_values = list(similarities.values())
        plt.figure(figsize=(15, 6))
        plt.hist(sim_values, bins=30, edgecolor='black')
        plt.title('Similarity Distribution Between Transformations')
        plt.xlabel('Similarity')
        plt.ylabel('Frequency')
        plt.tight_layout()
        plt.savefig('similarity_distribution.png')
        plt.close()

    def statistical_summary(self, entropies, similarities):
        """Genera un resumen estadístico de los resultados"""
        print("\n--- Statistical Summary ---")

        # Entropía
        entropy_values = list(entropies.values())
        print("\nEntropy:")
        print(f"Mean: {np.mean(entropy_values):.4f}")
        print(f"Standard Deviation: {np.std(entropy_values):.4f}")
        print(f"Minimum: {np.min(entropy_values):.4f}")
        print(f"Máximum: {np.max(entropy_values):.4f}")

        # Similitudes
        sim_values = list(similarities.values())
        print("\nSimilarity Between Transformations:")
        print(f"Mean: {np.mean(sim_values):.4f}")
        print(f"Standard Deviation: {np.std(sim_values):.4f}")
        print(f"Minimum: {np.min(sim_values):.4f}")
        print(f"Máximum: {np.max(sim_values):.4f}")

    def full_analysis(self):
        """Realiza análisis completo"""
        # Generar 1000 contraseñas
        passwords = self.generate_passwords(1000)

        # Cálculo de entropía
        entropies = self.calculate_entropy(passwords)

        # Análisis de similitud
        similarities = self.similarity_analysis(passwords[:100])  # Limitar para rendimiento

        # Visualización
        self.visualize_results(entropies, similarities)

        # Resumen estadístico
        self.statistical_summary(entropies, similarities)

# Usar el script
analyzer = CryptoAnalyzer('./script.sh')
analyzer.full_analysis()
