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
import platform
import cpuinfo

# Translation dictionary
TRANSLATIONS = {
    'en': {
        'start_analysis': "Starting analysis with {} tests...",
        'processing': "Processing encryptions",
        'analyzing': "\nAnalyzing {} successful results...",
        'testing_rev': "\nTesting reversibility...",
        'verifying': "Verifying reversibility",
        'completed': "\nAnalysis completed. Results saved in: {}",
        'seed_phrase_used': "Seed phrase used for analysis",
        'words': "words",
        'iterations_used': "Iterations used",
        'avg_transform_time': "Average transformation time",
        'performance_metrics': "Performance Metrics",
        'reversion_performance': "Reversion Performance",
        'avg_reversion_time': "Average reversion time",
        'total_reversions': "Total reversions",
        'fastest_reversion': "Fastest reversion",
        'slowest_reversion': "Slowest reversion"
    },
    'es': {
        'start_analysis': "Iniciando análisis con {} pruebas...",
        'processing': "Procesando cifrados",
        'analyzing': "\nAnalizando {} resultados exitosos...",
        'testing_rev': "\nProbando reversibilidad...",
        'verifying': "Verificando reversibilidad",
        'completed': "\nAnálisis completado. Resultados guardados en: {}",
        'seed_phrase_used': "Frase semilla utilizada para el análisis",
        'words': "palabras",
        'iterations_used': "Iteraciones utilizadas",
        'avg_transform_time': "Tiempo promedio de transformación",
        'performance_metrics': "Métricas de Rendimiento",
        'reversion_performance': "Rendimiento de Reversión",
        'avg_reversion_time': "Tiempo promedio de reversión",
        'total_reversions': "Total de reversiones",
        'fastest_reversion': "Reversión más rápida",
        'slowest_reversion': "Reversión más lenta"
    }
}


class EnhancedAnalyzer:
    def __init__(self, bash_script_path: str, n_tests: int = 10000, debug: bool = False,
                 password_mode: str = 'random', resource_level: int = 3,
                 language: str = 'en', rev_tests: int = 100, seed_phrase: Optional[str] = None, iterations: int = 1):
        """
        Initialize the analyzer with custom parameters.
        """
        self.bash_script_path = bash_script_path
        self.n_tests = n_tests
        self.debug = debug
        self.password_mode = password_mode
        self.language = language
        self.rev_tests = rev_tests
        self.iterations = iterations  # New parameter for iterations
        self.system_info = self._get_system_info()
        self.transform_times = []
        self.reversion_times = []
        self.process = None

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

        self.default_seed = [
            "ribbon", "slight", "frog", "oxygen", "range",
            "slam", "destroy", "dune", "fossil", "slow",
            "decrease", "primary", "hint", "loan", "limb",
            "palm", "act", "reward", "foot", "deposit",
            "response", "fashion", "under", "sail"
        ]

        if seed_phrase:
            self.test_seed = seed_phrase.split()
        else:
            self.test_seed = self.default_seed.copy()

        # Setup directories
        self.results_dir = "analysis_results"
        self.plots_dir = os.path.join(self.results_dir, "plots")
        os.makedirs(self.results_dir, exist_ok=True)
        os.makedirs(self.plots_dir, exist_ok=True)

    def initialize_process(self):
        """
        Inicializa el proceso una sola vez y lo mantiene vivo.
        """
        if self.process is None:
            self.process = subprocess.Popen(
                [self.bash_script_path, '-s'],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env={"TERM": "xterm"}
            )

    def _get_system_info(self) -> Dict:
        """
        Get detailed system information.
        """
        try:
            cpu_info = cpuinfo.get_cpu_info()
        except Exception:
            cpu_info = {"brand_raw": "Unknown CPU"}

        memory = psutil.virtual_memory()

        return {
            "os": platform.system(),
            "os_version": platform.version(),
            "architecture": platform.machine(),
            "processor": cpu_info.get("brand_raw", "Unknown"),
            "physical_cores": psutil.cpu_count(logical=False),
            "total_cores": psutil.cpu_count(logical=True),
            "memory_total": f"{memory.total / (1024**3):.2f} GB",
            "memory_available": f"{memory.available / (1024**3):.2f} GB",
            "memory_used_percent": f"{memory.percent}%"
        }

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

    def run_cipher(self, password: str, words: Optional[List[str]] = None) -> Optional[Tuple[List[str], float]]:
        max_retries = 2  # Número de intentos si falla
        for attempt in range(max_retries):
            try:
                if self.process is None:
                    self.initialize_process()

                input_words = words if words is not None else self.test_seed
                seed_phrase = ' '.join(input_words)

                # Solo medimos el tiempo de la operación real
                start_time = time.time()

                # Enviar entrada al proceso
                self.process.stdin.write(f"{seed_phrase}\n{password}\n{self.iterations}\n")
                self.process.stdin.flush()

                # Leer hasta que encontremos una línea no vacía o un error
                output = ""
                while True:
                    line = self.process.stdout.readline()
                    if line.strip():
                        output = line
                        break
                    if not line:  # EOF
                        break

                error = self.process.stderr.readline()
                end_time = time.time()
                process_time = end_time - start_time

                if self.debug:
                    print("\nDEBUG Information:")
                    print(f"Input seed phrase: {seed_phrase}")
                    print(f"Input password: {password}")
                    print(f"Using iterations: {self.iterations}")
                    print(f"Operation type: {'Reversion' if words is not None else 'Initial transform'}")
                    print(f"Raw stdout: {output}")
                    print(f"Raw stderr: {error}")
                    print(f"Process time: {process_time:.4f} seconds")

                if output and output.strip():
                    result = output.strip().split()
                    if words is None:
                        return result, process_time  # Para transformación inicial
                    else:
                        return result, process_time  # Para reversión

                # Si llegamos aquí sin resultado, reiniciamos el proceso
                if self.process is not None:
                    self.process.terminate()
                    self.process = None

            except (BrokenPipeError, IOError) as e:
                if self.debug:
                    print(f"Error in run_cipher: {e}")
                if self.process is not None:
                    self.process.terminate()
                    self.process = None
                if attempt == max_retries - 1:  # Si es el último intento
                    return None
                # Si no es el último intento, continuamos con el siguiente
                continue

            except Exception as e:
                if self.debug:
                    print(f"Error in run_cipher: {e}")
                if self.process is not None:
                    self.process.terminate()
                    self.process = None
                return None

        return None  # Si todos los intentos fallan

    def test_reversibility(self, cipher_result: List[str], password: str) -> Dict:
        """
        Test cipher reversibility.
        """
        try:
            if not cipher_result or len(cipher_result) != len(self.test_seed):
                return {"success": False, "error": "Invalid initial cipher result"}

            start_time = time.time()  # Medimos el tiempo solo para la reversión
            reverse_result, _ = self.run_cipher(password, cipher_result)
            end_time = time.time()
            self.reversion_times.append(end_time - start_time)


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

        # Calculate distribution stats with warning handling
        values = list(counts.values())
        try:
            with np.errstate(all='ignore'):  # Temporarily suppress numpy warnings
                skewness = float(stats.skew(values))
                kurtosis = float(stats.kurtosis(values))

            # Check if values are too similar
            if np.std(values) < 1e-7:  # Threshold for "nearly identical"
                skewness = 0.0  # For perfectly symmetric distribution
                kurtosis = -3.0  # For perfectly uniform distribution
        except:
            skewness = 0.0
            kurtosis = -3.0

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
                'skewness': skewness,
                'kurtosis': kurtosis,
                'note': "Values are nearly identical" if np.std(values) < 1e-7 else None
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
        # System Information
        print_and_save("\nSystem Information:")
        print_and_save(f"OS: {self.system_info['os']} {self.system_info['os_version']}")
        print_and_save(f"Architecture: {self.system_info['architecture']}")
        print_and_save(f"Processor: {self.system_info['processor']}")
        print_and_save(f"Physical Cores: {self.system_info['physical_cores']}")
        print_and_save(f"Total Cores: {self.system_info['total_cores']}")
        print_and_save(f"Memory Total: {self.system_info['memory_total']}")
        print_and_save(f"Memory Available: {self.system_info['memory_available']}")
        print_and_save(f"Memory Usage: {self.system_info['memory_used_percent']}")
        print_and_save(f"\n{self.texts['seed_phrase_used']}:")
        print_and_save(f"- {' '.join(self.test_seed)}")
        print_and_save(f"- {self.texts['words'] if self.language == 'en' else 'palabras'}: {len(self.test_seed)}")
        print_and_save("")
        print_and_save(f"\nPassword Mode: {self.password_mode}")
        print_and_save(f"Resource Level: {list(self.resource_configs.keys())[list(self.resource_configs.values()).index(self.resource_config)]}")
        print_and_save(f"Number of Tests: {self.n_tests}")
        print_and_save(f"Reversibility Tests: {self.rev_tests}")
        print_and_save(f"Language: {self.language}")
        print_and_save(f"{self.texts['iterations_used']}: {self.iterations}")

        # Performance Metrics
        print_and_save(f"\n{self.texts['performance_metrics']}:")
        print_and_save("="*50)

        # Initial transformations performance
        print_and_save("\nTransformation Performance:")
        print_and_save("-" * 30)
        if len(self.transform_times) > 0:
            print_and_save(f"Total transformations executed: {self.n_tests}")
            print_and_save(f"Successful transformations: {len(self.transform_times)}")
            if self.iterations > 1:
                print_and_save(f"Using {self.iterations} iterations per transformation")
        else:
            print_and_save("No transformation times recorded")

        # Reversion performance
        rev_stats = analysis.get('reversibility_analysis', {})
        if rev_stats:  # Cambiamos la condición aquí
            print_and_save("\nReversion Performance:")
            print_and_save("-" * 30)
            print_and_save(f"Tests performed: {rev_stats['total_tests']}")
            print_and_save(f"Successful reversals: {rev_stats['successful_reversals']}")
            print_and_save(f"Failed reversals: {rev_stats['failed_reversals']}")
            print_and_save(f"Success rate: {(rev_stats['successful_reversals']/rev_stats['total_tests'])*100:.2f}%")
            if self.iterations > 1:
                print_and_save(f"Using {self.iterations} iterations per reversion")

            if rev_stats['failed_reversals'] > 0:
                print_and_save("\nFAILURE DETAILS:" if self.language == 'en' else "\nDETALLE DE FALLOS:")
                for detail in rev_stats['detailed_results'][:5]:
                    if not detail['is_reversible']:
                        print_and_save(f"- Differences found: {len(detail['differences'])}")
                        for diff in detail['differences']:
                            print_and_save(f"  Position {diff['position']}: {diff['original']} -> {diff['got']}")



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



        # Position analysis
        title = "2. POSITION ANALYSIS" if self.language == 'en' else "3. ANÁLISIS POR POSICIÓN"
        print_and_save(f"\n{title}")
        print_and_save("-"*30)
        for pos in range(len(self.test_seed)):
            stats = analysis['position_stats'][pos]
            print_and_save(f"\nPosition {pos + 1}:")
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
        title = "3. PATTERN ANALYSIS" if self.language == 'en' else "4. ANÁLISIS DE PATRONES"
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
        title = "4. WORD DISTRIBUTION" if self.language == 'en' else "5. DISTRIBUCIÓN DE PALABRAS"
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
        title = "5. EXECUTION STATISTICS" if self.language == 'en' else "6. ESTADÍSTICAS DE EJECUCIÓN"
        print_and_save(f"\n{title}")
        print_and_save("-"*30)
        print_and_save(f"Total execution time: {analysis['execution_stats']['total_time']:.2f} seconds" if self.language == 'en' else
                      f"Tiempo total de ejecución: {analysis['execution_stats']['total_time']:.2f} segundos")
        print_and_save(f"Timestamp: {analysis['execution_stats']['timestamp']}")

        # Generated files
        title = "6. GENERATED FILES" if self.language == 'en' else "7. ARCHIVOS GENERADOS"
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

    def process_reversion_pair(self, pair):
        """
        Procesa un par de (password, result) para testing de reversibilidad.
        """
        password, result = pair
        return self.test_reversibility(result, password)

    def analyze(self) -> Dict:
        """
        Perform complete analysis and return results with parallel reversions.
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        start_time = time.time()
        terminal_output = []

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

        # Filter valid results and collect times
        valid_results = []
        self.transform_times = []  # Reset transform_times
        for result in results:
                if result is not None:
                        output, process_time = result
                        if process_time is not None:  # Solo para transformaciones iniciales
                                self.transform_times.append(process_time)
                        valid_results.append(output)

        if not valid_results:
                raise ValueError("No valid results obtained")

        print(self.texts['analyzing'].format(len(valid_results)))
        terminal_output.append(self.texts['analyzing'].format(len(valid_results)))

        # Main analysis
        analysis = self.analyze_distribution(valid_results)

        # Reversibility tests
        print(self.texts['testing_rev'])
        terminal_output.append(self.texts['testing_rev'])
        test_pairs = list(zip(passwords[:self.rev_tests], valid_results[:self.rev_tests]))

        # Ejecutar reversiones en paralelo usando el mismo pool
        with mp.Pool(processes=self.resource_config['processes']) as pool:
                reversibility_results = list(tqdm(
                        pool.imap(self.process_reversion_pair, test_pairs),
                        total=len(test_pairs),
                        desc=self.texts['verifying']
                ))

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

    def __del__(self):
        """
        Asegura que el proceso se cierre al finalizar.
        """
        if self.process is not None:
            self.process.terminate()

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
    parser.add_argument('--seed-phrase', '-sp', type=str,
                      help='Custom seed phrase to use for testing (space-separated words)')
    parser.add_argument('--iterations', '-i', type=int, default=1,
                      help='Number of mixing iterations to perform (default: 1)')

    args = parser.parse_args()

    analyzer = EnhancedAnalyzer(
        bash_script_path=args.script,
        n_tests=args.tests,
        debug=args.debug,
        password_mode=args.password_mode,
        resource_level=args.resource_level,
        language=args.language,
        rev_tests=args.rev_tests,
        seed_phrase=args.seed_phrase,
        iterations=args.iterations
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
