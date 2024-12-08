import numpy as np
from typing import List, Dict, Tuple, Optional
from collections import Counter, defaultdict
import pandas as pd
from scipy import stats, signal
import multiprocessing as mp
from concurrent.futures import ThreadPoolExecutor
import subprocess
from tqdm import tqdm
import json
import os
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

class EnhancedAnalyzer:
    def __init__(self, bash_script_path: str, n_tests: int = 10000, debug: bool = False):
        self.bash_script_path = bash_script_path
        self.n_tests = n_tests
        self.debug = debug
        self.test_seed = [
            "ribbon", "slight", "frog", "oxygen", "range",
            "slam", "destroy", "dune", "fossil", "slow",
            "decrease", "primary", "hint", "loan", "limb",
            "palm", "act", "reward", "foot", "deposit",
            "response", "fashion", "under", "sail"
        ]
        self.results_dir = "analysis_results"
        self.plots_dir = os.path.join(self.results_dir, "plots")
        os.makedirs(self.results_dir, exist_ok=True)
        os.makedirs(self.plots_dir, exist_ok=True)

    def run_cipher(self, password: str, words: Optional[List[str]] = None) -> Optional[List[str]]:
        try:
            input_words = words if words is not None else self.test_seed
            process = subprocess.Popen(
                [self.bash_script_path] + input_words,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env={"TERM": "xterm"}
            )
            stdout, stderr = process.communicate(input=f"{password}\n", timeout=5)
            if process.returncode == 0:
                return stdout.strip().split()
            if self.debug and stderr:
                print(f"Error en el proceso: {stderr}")
            return None
        except Exception as e:
            if self.debug:
                print(f"Error en run_cipher: {e}")
            return None

    def test_reversibility(self, cipher_result: List[str], password: str) -> Dict:
        """
        Prueba la reversibilidad del cifrado usando la misma contraseña
        que se usó para generar el resultado inicial.
        """
        try:
            # Verificar entrada válida
            if not cipher_result or len(cipher_result) != len(self.test_seed):
                return {"success": False, "error": "Invalid initial cipher result"}

            # Usar la misma contraseña para revertir
            reverse_result = self.run_cipher(password, cipher_result)
            if not reverse_result:
                return {"success": False, "error": "Failed to reverse cipher"}

            # Comparar con la semilla original
            is_reversible = (self.test_seed == reverse_result)
            differences = []

            if not is_reversible:
                differences = [
                    {
                        "position": i,
                        "original": orig,
                        "got": rev
                    }
                    for i, (orig, rev) in enumerate(zip(self.test_seed, reverse_result))
                    if orig != rev
                ]

            return {
                "success": True,
                "is_reversible": is_reversible,
                "differences": differences,
                "original": self.test_seed,
                "first_cipher": cipher_result,
                "reversed": reverse_result
            }

        except Exception as e:
            if self.debug:
                print(f"Error en test_reversibility: {str(e)}")
            return {"success": False, "error": str(e)}

    def generate_passwords(self) -> List[str]:
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return [
            ''.join(np.random.choice(list(chars), size=np.random.randint(8, 20)))
            for _ in range(self.n_tests)
        ]

    def analyze_sequence(self, sequence: List[str]) -> Dict:
        numeric_seq = np.array([hash(word) for word in sequence])
        normalized_seq = (numeric_seq - np.mean(numeric_seq)) / np.std(numeric_seq)

        autocorr = []
        for lag in range(1, min(11, len(sequence))):
            corr = np.corrcoef(normalized_seq[:-lag], normalized_seq[lag:])[0,1]
            autocorr.append(float(corr))

        fft = np.fft.fft(normalized_seq)
        power = np.abs(fft)**2
        freqs = np.fft.fftfreq(len(normalized_seq))

        peaks = signal.find_peaks(power[:len(power)//2])[0]
        main_frequencies = sorted(
            [(abs(freqs[p]), float(power[p])) for p in peaks],
            key=lambda x: x[1],
            reverse=True
        )[:5]

        return {
            'autocorrelation': autocorr,
            'main_frequencies': main_frequencies
        }

    def analyze_distribution(self, results: List[List[str]]) -> Dict:
        n_positions = len(self.test_seed)
        analysis = {
            'position_stats': {},
            'global_stats': {},
            'sequence_analysis': {}
        }

        for pos in range(n_positions):
            words_at_pos = [result[pos] for result in results]
            counts = Counter(words_at_pos)
            total = len(words_at_pos)

            probs = [count/total for count in counts.values()]
            entropy = -sum(p * np.log2(p) for p in probs)

            expected = np.array([total/len(counts)] * len(counts))
            observed = np.array(list(counts.values()))
            chi2, p_value = stats.chisquare(observed, expected)

            seq_analysis = self.analyze_sequence(words_at_pos)

            analysis['position_stats'][pos] = {
                'entropy': float(entropy),
                'chi_square': float(chi2),
                'p_value': float(p_value),
                'unique_words': len(counts),
                'most_common': counts.most_common(10),
                'sequence_metrics': seq_analysis
            }

        all_words = [word for result in results for word in result]
        global_counts = Counter(all_words)

        analysis['global_stats'] = {
            'total_words': len(all_words),
            'unique_words': len(global_counts),
            'most_common': global_counts.most_common(20),
            'average_frequency': len(all_words) / len(global_counts)
        }

        for i, result in enumerate(results[:100]):
            analysis['sequence_analysis'][i] = self.analyze_sequence(result)

        return analysis

    def generate_plots(self, analysis: Dict, timestamp: str):
        # Plot de entropía
        plt.figure(figsize=(12, 6))
        positions = sorted(analysis['position_stats'].keys())
        entropies = [analysis['position_stats'][p]['entropy'] for p in positions]
        plt.plot(positions, entropies, 'b-', marker='o')
        plt.title('Entropía por Posición')
        plt.xlabel('Posición')
        plt.ylabel('Entropía (bits)')
        plt.grid(True)
        plt.savefig(f"{self.plots_dir}/entropy_{timestamp}.png")
        plt.close()

        # Plot de autocorrelación
        plt.figure(figsize=(12, 6))
        avg_autocorr = np.zeros(10)
        for pos in positions:
            autocorr = analysis['position_stats'][pos]['sequence_metrics']['autocorrelation']
            avg_autocorr += np.array(autocorr[:10])
        avg_autocorr /= len(positions)

        plt.plot(range(1, 11), avg_autocorr, 'r-', marker='o')
        plt.title('Autocorrelación Promedio')
        plt.xlabel('Lag')
        plt.ylabel('Correlación')
        plt.grid(True)
        plt.savefig(f"{self.plots_dir}/autocorrelation_{timestamp}.png")
        plt.close()

        # Plot de distribución
        plt.figure(figsize=(15, 8))
        words, counts = zip(*analysis['global_stats']['most_common'][:20])
        plt.bar(words, counts)
        plt.title('20 Palabras Más Frecuentes')
        plt.xticks(rotation=45, ha='right')
        plt.ylabel('Frecuencia')
        plt.tight_layout()
        plt.savefig(f"{self.plots_dir}/word_distribution_{timestamp}.png")
        plt.close()

    def analyze(self) -> Dict:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        print(f"\nIniciando análisis con {self.n_tests} pruebas...")

        # Generar contraseñas
        passwords = self.generate_passwords()

        # Ejecutar pruebas en paralelo y mantener las contraseñas asociadas
        with mp.Pool() as pool:
            results = list(tqdm(
                pool.imap(self.run_cipher, passwords),
                total=self.n_tests,
                desc="Procesando cifrados"
            ))

        # Filtrar resultados None pero mantener el mapeo con las contraseñas
        valid_results = [(password, result)
                        for password, result in zip(passwords, results)
                        if result is not None]

        if not valid_results:
            raise ValueError("No se obtuvieron resultados válidos")

        passwords_valid, results_valid = zip(*valid_results)

        print(f"\nAnalizando {len(results_valid)} resultados exitosos...")

        # Análisis principal
        analysis = self.analyze_distribution(results_valid)

        # Pruebas de reversibilidad
        print("\nProbando reversibilidad...")
        reversibility_results = []

        # Usar los primeros 100 resultados válidos con sus contraseñas correspondientes
        test_pairs = list(zip(passwords_valid[:100], results_valid[:100]))

        for password, result in tqdm(test_pairs, desc="Verificando reversibilidad"):
            rev_test = self.test_reversibility(result, password)
            reversibility_results.append(rev_test)

        # Analizar resultados de reversibilidad
        reversibility_stats = {
            "total_tests": len(reversibility_results),
            "successful_reversals": sum(1 for r in reversibility_results if r["success"] and r["is_reversible"]),
            "failed_reversals": sum(1 for r in reversibility_results if r["success"] and not r["is_reversible"]),
            "errors": sum(1 for r in reversibility_results if not r["success"]),
            "detailed_results": reversibility_results[:10]  # Primeros 10 resultados detallados
        }

        analysis["reversibility_analysis"] = reversibility_stats

        # Generar visualizaciones
        self.generate_plots(analysis, timestamp)

        # Guardar resultados
        results_file = os.path.join(self.results_dir, f"analysis_{timestamp}.json")
        with open(results_file, 'w') as f:
            json.dump(analysis, f, indent=2, default=str)

        # Mostrar resumen
        print("\n=== Resumen del Análisis ===")
        print(f"Total de pruebas ejecutadas: {self.n_tests}")
        print(f"Pruebas exitosas: {len(results_valid)}")
        print(f"Tasa de éxito: {(len(results_valid)/self.n_tests)*100:.2f}%")

        print("\nAnálisis de Reversibilidad:")
        print(f"Tests realizados: {reversibility_stats['total_tests']}")
        print(f"Reversiones exitosas: {reversibility_stats['successful_reversals']}")
        print(f"Reversiones fallidas: {reversibility_stats['failed_reversals']}")
        print(f"Errores: {reversibility_stats['errors']}")

        if reversibility_stats['failed_reversals'] > 0:
            print("\n¡ADVERTENCIA! Se detectaron fallos en la reversibilidad")
            print("Revisa los resultados detallados en el archivo JSON")

        print("\nPruebas de uniformidad (Chi-square):")
        for pos in range(len(self.test_seed)):
            stats = analysis['position_stats'][pos]
            print(f"Posición {pos}: p-value = {stats['p_value']:.4f}")

        print("\nPalabras más frecuentes:")
        for word, count in analysis['global_stats']['most_common'][:10]:
            print(f"'{word}': {count} veces")

        return analysis

if __name__ == "__main__":
    analyzer = EnhancedAnalyzer('./scypher.sh', n_tests=10000, debug=True)
    results = analyzer.analyze()
