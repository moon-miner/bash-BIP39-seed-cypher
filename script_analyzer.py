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
import argparse
import time
import psutil
import math
import sys


# Translation dictionary
TRANSLATIONS = {
    'en': {
        'start_analysis': "Starting analysis with {} tests...",
        'processing': "Processing encryptions",
        'analyzing': "\nAnalyzing {} successful results...",
        'testing_rev': "\nTesting reversibility...",
        'verifying': "Verifying reversibility",
        'completed': "\nAnalysis completed. Results saved in: {}"
    },
    'es': {
        'start_analysis': "Iniciando análisis con {} pruebas...",
        'processing': "Procesando cifrados",
        'analyzing': "\nAnalizando {} resultados exitosos...",
        'testing_rev': "\nProbando reversibilidad...",
        'verifying': "Verificando reversibilidad",
        'completed': "\nAnálisis completado. Resultados guardados en: {}"
    }
}


class EnhancedAnalyzer:
    def __init__(self, bash_script_path: str, n_tests: int = 10000, debug: bool = False,
                 password_mode: str = 'random', resource_level: int = 3,
                 language: str = 'en', rev_tests: int = 100):
        """
        Initialize the analyzer with custom parameters.
        """
        self.bash_script_path = bash_script_path
        self.n_tests = n_tests
        self.debug = debug
        self.password_mode = password_mode
        self.language = language
        self.rev_tests = rev_tests

        # Configure resources based on level
        cpu_count = mp.cpu_count()
        self.resource_configs = {
            1: {  # Low
                'processes': max(1, cpu_count // 4),
                'batch_size': 1000,
                'memory_limit': 0.25
            },
            2: {  # Medium
                'processes': max(1, cpu_count // 2),
                'batch_size': 5000,
                'memory_limit': 0.5
            },
            3: {  # High
                'processes': cpu_count,
                'batch_size': 10000,
                'memory_limit': 0.75
            }
        }

        self.resource_config = self.resource_configs[resource_level]
        self.texts = TRANSLATIONS[language]

        self.test_seed = [
            "ribbon", "slight", "frog", "oxygen", "range",
            "slam", "destroy", "dune", "fossil", "slow",
            "decrease", "primary", "hint", "loan", "limb",
            "palm", "act", "reward", "foot", "deposit",
            "response", "fashion", "under", "sail"
        ]

        # Setup directories
        self.results_dir = "analysis_results"
        self.plots_dir = os.path.join(self.results_dir, "plots")
        os.makedirs(self.results_dir, exist_ok=True)
        os.makedirs(self.plots_dir, exist_ok=True)

    def generate_random_passwords(self) -> List[str]:
        """
        Generate random passwords maximizing differences between them.
        """
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        passwords = set()  # Using set to ensure uniqueness
        batch_size = self.resource_config['batch_size']

        while len(passwords) < self.n_tests:
            # Generate a batch of passwords
            new_batch = {
                ''.join(np.random.choice(list(chars), size=np.random.randint(8, 20)))
                for _ in range(min(batch_size, self.n_tests - len(passwords)))
            }
            passwords.update(new_batch)

        return list(passwords)[:self.n_tests]

    def generate_similar_passwords(self) -> List[str]:
        """
        Generate passwords with minimal variations between them.
        """
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        chars_map = {c: i for i, c in enumerate(chars)}

        base = list("aaaaAAA111")  # Base password
        password_length = len(base)
        passwords = []
        positions = list(range(password_length))

        def increment_position(pos: int) -> bool:
            current = base[pos]
            current_idx = chars_map[current]

            if current_idx + 1 >= len(chars):
                base[pos] = chars[0]
                return True
            else:
                base[pos] = chars[current_idx + 1]
                return False

        def generate_next() -> str:
            pos = positions[0]
            while increment_position(pos):
                pos_idx = positions.index(pos)
                if pos_idx + 1 >= len(positions):
                    pos = positions[0]
                    positions.append(positions.pop(0))
                else:
                    pos = positions[pos_idx + 1]
            return ''.join(base)

        for _ in range(self.n_tests):
            passwords.append(generate_next())

        return passwords

    def generate_passwords(self) -> List[str]:
        """
        Generate passwords according to selected mode.
        """
        if self.password_mode == 'similar':
            return self.generate_similar_passwords()
        return self.generate_random_passwords()

    def run_cipher(self, password: str, words: Optional[List[str]] = None) -> Optional[List[str]]:
        """
        Execute cipher with given password.
        """
        try:
            input_words = words if words is not None else self.test_seed
            seed_phrase = ' '.join(input_words)

            process = subprocess.Popen(
                [self.bash_script_path, '-s'],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env={"TERM": "xterm"}
            )

            stdout, stderr = process.communicate(input=f"{seed_phrase}\n{password}\n", timeout=5)

            if process.returncode == 0 and stdout.strip():
                return stdout.strip().split()

            if self.debug and stderr:
                print(f"Error in process: {stderr}")
            return None
        except Exception as e:
            if self.debug:
                print(f"Error in run_cipher: {e}")
            return None

    def test_reversibility(self, cipher_result: List[str], password: str) -> Dict:
        """
        Test cipher reversibility.
        """
        try:
            if not cipher_result or len(cipher_result) != len(self.test_seed):
                return {"success": False, "error": "Invalid initial cipher result"}

            reverse_result = self.run_cipher(password, cipher_result)
            if not reverse_result:
                return {"success": False, "error": "Failed to reverse cipher"}

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
                print(f"Error in test_reversibility: {str(e)}")
            return {"success": False, "error": str(e)}

    def analyze_sequence(self, sequence: List[str]) -> Dict:
        """
        Analyze a sequence of words.
        """
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
            'main_frequencies': main_frequencies,
            'sequence_stats': {
                'mean': float(np.mean(numeric_seq)),
                'std': float(np.std(numeric_seq)),
                'skewness': float(stats.skew(numeric_seq)),
                'kurtosis': float(stats.kurtosis(numeric_seq))
            }
        }

    def calculate_position_metrics(self, position_data: List[str]) -> Dict:
        """
        Calculate detailed metrics for a specific position.
        """
        counts = Counter(position_data)
        total = len(position_data)

        probs = [count/total for count in counts.values()]
        entropy = -sum(p * np.log2(p) for p in probs)

        expected = np.array([total/len(counts)] * len(counts))
        observed = np.array(list(counts.values()))
        chi2, p_value = stats.chisquare(observed, expected)

        numeric_seq = np.array([hash(word) for word in position_data])
        normalized_seq = (numeric_seq - np.mean(numeric_seq)) / np.std(numeric_seq)

        autocorr = []
        for lag in range(1, min(11, len(position_data))):
            corr = np.corrcoef(normalized_seq[:-lag], normalized_seq[lag:])[0,1]
            autocorr.append(float(corr))

        return {
            'entropy': float(entropy),
            'chi_square': float(chi2),
            'p_value': float(p_value),
            'unique_words': len(counts),
            'most_common': counts.most_common(10),
            'least_common': counts.most_common()[:-11:-1],
            'autocorrelation': autocorr,
            'mean': float(np.mean(list(counts.values()))),
            'std_dev': float(np.std(list(counts.values()))),
            'median': float(np.median(list(counts.values()))),
            'distribution_stats': {
                'skewness': float(stats.skew(list(counts.values()))),
                'kurtosis': float(stats.kurtosis(list(counts.values())))
            }
        }

    def analyze_distribution(self, results: List[List[str]]) -> Dict:
        """
        Analyze word distribution in results.
        """
        n_positions = len(self.test_seed)
        analysis = {
            'position_stats': {},
            'global_stats': {},
            'sequence_analysis': {}
        }

        for pos in range(n_positions):
            words_at_pos = [result[pos] for result in results]
            analysis['position_stats'][pos] = self.calculate_position_metrics(words_at_pos)

        all_words = [word for result in results for word in result]
        global_counts = Counter(all_words)

        analysis['global_stats'] = {
            'total_words': len(all_words),
            'unique_words': len(global_counts),
            'most_common': global_counts.most_common(20),
            'average_frequency': len(all_words) / len(global_counts),
            'word_frequency_stats': {
                'mean': float(np.mean(list(global_counts.values()))),
                'std_dev': float(np.std(list(global_counts.values()))),
                'median': float(np.median(list(global_counts.values()))),
                'skewness': float(stats.skew(list(global_counts.values()))),
                'kurtosis': float(stats.kurtosis(list(global_counts.values())))
            }
        }

        for i, result in enumerate(results[:100]):
            analysis['sequence_analysis'][i] = self.analyze_sequence(result)

        return analysis

    def generate_plots(self, analysis: Dict, timestamp: str):
        """
        Generate visualization plots.
        """
        # Entropy plot
        plt.figure(figsize=(12, 6))
        positions = sorted(analysis['position_stats'].keys())
        entropies = [analysis['position_stats'][p]['entropy'] for p in positions]
        plt.plot(positions, entropies, 'b-', marker='o')
        plt.title('Entropy by Position' if self.language == 'en' else 'Entropía por Posición')
        plt.xlabel('Position' if self.language == 'en' else 'Posición')
        plt.ylabel('Entropy (bits)' if self.language == 'en' else 'Entropía (bits)')
        plt.grid(True)
        plt.savefig(f"{self.plots_dir}/entropy_{timestamp}.png")
        plt.close()

        # Autocorrelation plot
        plt.figure(figsize=(12, 6))
        avg_autocorr = np.zeros(10)
        for pos in positions:
            autocorr = analysis['position_stats'][pos]['autocorrelation']
            avg_autocorr += np.array(autocorr[:10])
        avg_autocorr /= len(positions)

        plt.plot(range(1, 11), avg_autocorr, 'r-', marker='o')
        plt.title('Average Autocorrelation' if self.language == 'en' else 'Autocorrelación Promedio')
        plt.xlabel('Lag')
        plt.ylabel('Correlation' if self.language == 'en' else 'Correlación')
        plt.grid(True)
        plt.savefig(f"{self.plots_dir}/autocorrelation_{timestamp}.png")
        plt.close()

        # Word distribution plot
        plt.figure(figsize=(15, 8))
        words, counts = zip(*analysis['global_stats']['most_common'][:20])
        plt.bar(words, counts)
        plt.title('20 Most Frequent Words' if self.language == 'en' else '20 Palabras Más Frecuentes')
        plt.xticks(rotation=45, ha='right')
        plt.ylabel('Frequency' if self.language == 'en' else 'Frecuencia')
        plt.tight_layout()
        plt.savefig(f"{self.plots_dir}/word_distribution_{timestamp}.png")
        plt.close()

        # P-values distribution plot
        plt.figure(figsize=(12, 6))
        p_values = [analysis['position_stats'][p]['p_value'] for p in positions]
        plt.hist(p_values, bins=20, edgecolor='black')
        plt.title('P-values Distribution' if self.language == 'en' else 'Distribución de P-values')
        plt.xlabel('P-value')
        plt.ylabel('Frequency' if self.language == 'en' else 'Frecuencia')
        plt.grid(True)
        plt.savefig(f"{self.plots_dir}/pvalue_distribution_{timestamp}.png")
        plt.close()

    def print_detailed_results(self, analysis: Dict, timestamp: str, terminal_output: List[str]):
        """
        Print and save detailed analysis results.
        """
        # Start capturing output for file
        output_lines = []
        def print_and_save(text):
            print(text)
            output_lines.append(text)
            terminal_output.append(text)

        # Configuration summary
        print_and_save("\n" + "="*50)
        print_and_save("CONFIGURATION SUMMARY" if self.language == 'en' else "RESUMEN DE CONFIGURACIÓN")
        print_and_save("="*50)
        print_and_save(f"\nPassword Mode: {self.password_mode}")
        print_and_save(f"Resource Level: {list(self.resource_configs.keys())[list(self.resource_configs.values()).index(self.resource_config)]}")
        print_and_save(f"Number of Tests: {self.n_tests}")
        print_and_save(f"Reversibility Tests: {self.rev_tests}")
        print_and_save(f"Language: {self.language}")

        # Analysis results
        print_and_save("\n" + "="*50)
        print_and_save("DETAILED ANALYSIS RESULTS" if self.language == 'en' else "ANÁLISIS DETALLADO DE RESULTADOS")
        print_and_save("="*50)

        # Global statistics
        title = "1. GLOBAL STATISTICS" if self.language == 'en' else "1. ESTADÍSTICAS GLOBALES"
        print_and_save(f"\n{title}")
        print_and_save("-"*30)
        print_and_save(f"Total tests executed: {self.n_tests}" if self.language == 'en' else f"Total de pruebas ejecutadas: {self.n_tests}")
        print_and_save(f"Successful tests: {analysis['global_stats']['total_words'] // len(self.test_seed)}" if self.language == 'en' else
                      f"Pruebas exitosas: {analysis['global_stats']['total_words'] // len(self.test_seed)}")
        print_and_save(f"Total unique words: {analysis['global_stats']['unique_words']}" if self.language == 'en' else
                      f"Palabras únicas totales: {analysis['global_stats']['unique_words']}")
        print_and_save(f"Average frequency: {analysis['global_stats']['average_frequency']:.2f}" if self.language == 'en' else
                      f"Frecuencia promedio: {analysis['global_stats']['average_frequency']:.2f}")

        # Word frequency statistics
        stats = analysis['global_stats']['word_frequency_stats']
        print_and_save("\nWord frequency statistics:" if self.language == 'en' else "\nEstadísticas de frecuencia de palabras:")
        print_and_save(f"- Mean: {stats['mean']:.2f}")
        print_and_save(f"- Standard deviation: {stats['std_dev']:.2f}")
        print_and_save(f"- Median: {stats['median']:.2f}")
        print_and_save(f"- Skewness: {stats['skewness']:.2f}")
        print_and_save(f"- Kurtosis: {stats['kurtosis']:.2f}")

        # Reversibility analysis
        title = "2. REVERSIBILITY ANALYSIS" if self.language == 'en' else "2. ANÁLISIS DE REVERSIBILIDAD"
        print_and_save(f"\n{title}")
        print_and_save("-"*30)
        rev_stats = analysis['reversibility_analysis']
        print_and_save(f"Tests performed: {rev_stats['total_tests']}" if self.language == 'en' else f"Tests realizados: {rev_stats['total_tests']}")
        print_and_save(f"Successful reversals: {rev_stats['successful_reversals']}" if self.language == 'en' else
                      f"Reversiones exitosas: {rev_stats['successful_reversals']}")
        print_and_save(f"Failed reversals: {rev_stats['failed_reversals']}" if self.language == 'en' else
                      f"Reversiones fallidas: {rev_stats['failed_reversals']}")
        print_and_save(f"Success rate: {(rev_stats['successful_reversals']/rev_stats['total_tests'])*100:.2f}%" if self.language == 'en' else
                      f"Tasa de éxito: {(rev_stats['successful_reversals']/rev_stats['total_tests'])*100:.2f}%")

        if rev_stats['failed_reversals'] > 0:
            print_and_save("\nFAILURE DETAILS:" if self.language == 'en' else "\nDETALLE DE FALLOS:")
            for detail in rev_stats['detailed_results'][:5]:
                if not detail['is_reversible']:
                    print_and_save(f"- Differences found: {len(detail['differences'])}")
                    for diff in detail['differences']:
                        print_and_save(f"  Position {diff['position']}: {diff['original']} -> {diff['got']}")

        # Position analysis
        title = "3. POSITION ANALYSIS" if self.language == 'en' else "3. ANÁLISIS POR POSICIÓN"
        print_and_save(f"\n{title}")
        print_and_save("-"*30)
        for pos in range(len(self.test_seed)):
            stats = analysis['position_stats'][pos]
            print_and_save(f"\nPosition {pos}:")
            print_and_save(f"- Entropy: {stats['entropy']:.4f} bits")
            print_and_save(f"- P-value: {stats['p_value']:.4f}")
            print_and_save(f"- Chi-square: {stats['chi_square']:.4f}")
            print_and_save(f"- Unique words: {stats['unique_words']}")
            print_and_save(f"- Mean: {stats['mean']:.2f}")
            print_and_save(f"- Standard deviation: {stats['std_dev']:.2f}")
            print_and_save("- Most frequent words:")
            for word, count in stats['most_common'][:5]:
                print_and_save(f"  * '{word}': {count} times")
            print_and_save("- Least frequent words:")
            for word, count in stats['least_common'][:3]:
                print_and_save(f"  * '{word}': {count} times")
            print_and_save(f"- Autocorrelation (lag-1): {stats['autocorrelation'][0]:.4f}")

        # Pattern analysis
        title = "4. PATTERN ANALYSIS" if self.language == 'en' else "4. ANÁLISIS DE PATRONES"
        print_and_save(f"\n{title}")
        print_and_save("-"*30)
        print_and_save("Average autocorrelations by position:" if self.language == 'en' else "Autocorrelaciones promedio por posición:")
        avg_autocorr = np.zeros(10)
        for pos in range(len(self.test_seed)):
            avg_autocorr += np.array(analysis['position_stats'][pos]['autocorrelation'])
        avg_autocorr /= len(self.test_seed)
        for lag, corr in enumerate(avg_autocorr, 1):
            print_and_save(f"Lag-{lag}: {corr:.4f}")

        # Word distribution
        title = "5. WORD DISTRIBUTION" if self.language == 'en' else "5. DISTRIBUCIÓN DE PALABRAS"
        print_and_save(f"\n{title}")
        print_and_save("-"*30)
        print_and_save("Most frequent words:" if self.language == 'en' else "Palabras más frecuentes:")
        for word, count in analysis['global_stats']['most_common'][:10]:
            print_and_save(f"- '{word}': {count} times")
        print_and_save("\nLeast frequent words:" if self.language == 'en' else "\nPalabras menos frecuentes:")
        least_common = sorted(analysis['global_stats']['most_common'], key=lambda x: x[1])[:10]
        for word, count in least_common:
            print_and_save(f"- '{word}': {count} times")

        # Execution statistics
        title = "6. EXECUTION STATISTICS" if self.language == 'en' else "6. ESTADÍSTICAS DE EJECUCIÓN"
        print_and_save(f"\n{title}")
        print_and_save("-"*30)
        print_and_save(f"Total execution time: {analysis['execution_stats']['total_time']:.2f} seconds" if self.language == 'en' else
                      f"Tiempo total de ejecución: {analysis['execution_stats']['total_time']:.2f} segundos")
        print_and_save(f"Timestamp: {analysis['execution_stats']['timestamp']}")

        # Generated files
        title = "7. GENERATED FILES" if self.language == 'en' else "7. ARCHIVOS GENERADOS"
        print_and_save(f"\n{title}")
        print_and_save("-"*30)
        print_and_save(f"Results directory: {self.results_dir}")
        print_and_save(f"Plots saved in: {self.plots_dir}")
        print_and_save(f"Analysis file: analysis_{timestamp}.json")
        print_and_save(f"Terminal output: terminal_output_{timestamp}.txt")

        # Save terminal output
        output_file = os.path.join(self.results_dir, f"terminal_output_{timestamp}.txt")
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(output_lines))

    def analyze(self) -> Dict:
        """
        Perform complete analysis and return results.
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        start_time = time.time()
        terminal_output = []  # Para guardar la salida de la terminal

        print(self.texts['start_analysis'].format(self.n_tests))
        terminal_output.append(self.texts['start_analysis'].format(self.n_tests))

        # Generate passwords and run tests
        passwords = self.generate_passwords()
        with mp.Pool(processes=self.resource_config['processes']) as pool:
            results = list(tqdm(
                pool.imap(self.run_cipher, passwords),
                total=self.n_tests,
                desc=self.texts['processing']
            ))

        # Filter valid results
        valid_results = [(password, result)
                        for password, result in zip(passwords, results)
                        if result is not None]

        if not valid_results:
            raise ValueError("No valid results obtained")

        passwords_valid, results_valid = zip(*valid_results)

        print(self.texts['analyzing'].format(len(results_valid)))
        terminal_output.append(self.texts['analyzing'].format(len(results_valid)))

        # Main analysis
        analysis = self.analyze_distribution(results_valid)

        # Reversibility tests
        print(self.texts['testing_rev'])
        terminal_output.append(self.texts['testing_rev'])
        reversibility_results = []
        test_pairs = list(zip(passwords_valid[:self.rev_tests], results_valid[:self.rev_tests]))

        for password, result in tqdm(test_pairs, desc=self.texts['verifying']):
            rev_test = self.test_reversibility(result, password)
            reversibility_results.append(rev_test)

        # Reversibility statistics
        reversibility_stats = {
            "total_tests": len(reversibility_results),
            "successful_reversals": sum(1 for r in reversibility_results if r["success"] and r["is_reversible"]),
            "failed_reversals": sum(1 for r in reversibility_results if r["success"] and not r["is_reversible"]),
            "errors": sum(1 for r in reversibility_results if not r["success"]),
            "detailed_results": reversibility_results
        }

        analysis["reversibility_analysis"] = reversibility_stats

        # Generate visualizations
        self.generate_plots(analysis, timestamp)

        # Save results
        results_file = os.path.join(self.results_dir, f"analysis_{timestamp}.json")
        with open(results_file, 'w') as f:
            json.dump(analysis, f, indent=2, default=str)

        # Calculate total time
        total_time = time.time() - start_time
        analysis['execution_stats'] = {
            'total_time': total_time,
            'timestamp': timestamp
        }

        # Show detailed results
        self.print_detailed_results(analysis, timestamp, terminal_output)

        print(self.texts['completed'].format(self.results_dir))
        terminal_output.append(self.texts['completed'].format(self.results_dir))

        return analysis

def main():
    """
    Main function to handle command line arguments and execute analysis.
    """
    parser = argparse.ArgumentParser(description='Enhanced Cipher Analyzer')
    parser.add_argument('--script', '-s', default='./scypher.sh',
                      help='Path to cipher script (default: ./scypher.sh)')
    parser.add_argument('--tests', '-t', type=int, default=10000,
                      help='Number of tests to perform (default: 10000)')
    parser.add_argument('--debug', '-d', action='store_true',
                      help='Enable debug mode')
    parser.add_argument('--password-mode', '-p', choices=['random', 'similar'], default='random',
                      help='Password generation mode (default: random)')
    parser.add_argument('--resource-level', '-r', type=int, choices=[1, 2, 3], default=3,
                      help='Resource usage level - 1:low, 2:medium, 3:high (default: 2)')
    parser.add_argument('--language', '-l', choices=['en', 'es'], default='en',
                      help='Interface language (default: en)')
    parser.add_argument('--rev-tests', '-rv', type=int, default=100,
                      help='Number of reversibility tests to perform (default: 100)')

    args = parser.parse_args()

    analyzer = EnhancedAnalyzer(
        bash_script_path=args.script,
        n_tests=args.tests,
        debug=args.debug,
        password_mode=args.password_mode,
        resource_level=args.resource_level,
        language=args.language,
        rev_tests=args.rev_tests
    )

    try:
        results = analyzer.analyze()
    except Exception as e:
        print(f"Error during analysis: {str(e)}")
        if args.debug:
            raise
        sys.exit(1)


if __name__ == "__main__":
    main()
