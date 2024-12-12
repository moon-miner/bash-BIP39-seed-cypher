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

class EnhancedAnalyzer:
    def __init__(self, bash_script_path: str, n_tests: int = 10000, debug: bool = False):
        """
        Inicializa el analizador con parámetros personalizados.

        Args:
            bash_script_path (str): Ruta al script bash
            n_tests (int): Número de pruebas a realizar
            debug (bool): Modo debug
        """
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
        """
        Ejecuta el cifrado con una contraseña dada.

        Args:
            password (str): Contraseña para el cifrado
            words (List[str], optional): Lista de palabras a cifrar

        Returns:
            Optional[List[str]]: Lista de palabras cifradas o None si hay error
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
                print(f"Error en el proceso: {stderr}")
            return None
        except Exception as e:
            if self.debug:
                print(f"Error en run_cipher: {e}")
            return None

    def test_reversibility(self, cipher_result: List[str], password: str) -> Dict:
        """
        Prueba la reversibilidad del cifrado.

        Args:
            cipher_result (List[str]): Resultado del cifrado
            password (str): Contraseña usada

        Returns:
            Dict: Resultados de la prueba de reversibilidad
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
                print(f"Error en test_reversibility: {str(e)}")
            return {"success": False, "error": str(e)}

    def generate_passwords(self) -> List[str]:
        """
        Genera contraseñas aleatorias para las pruebas.

        Returns:
            List[str]: Lista de contraseñas generadas
        """
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return [
            ''.join(np.random.choice(list(chars), size=np.random.randint(8, 20)))
            for _ in range(self.n_tests)
        ]

    def analyze_sequence(self, sequence: List[str]) -> Dict:
        """
        Analiza una secuencia de palabras.

        Args:
            sequence (List[str]): Secuencia de palabras a analizar

        Returns:
            Dict: Resultados del análisis de secuencia
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
        Calcula métricas detalladas para una posición específica.

        Args:
            position_data (List[str]): Lista de palabras en una posición

        Returns:
            Dict: Métricas calculadas
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
        Analiza la distribución de palabras en los resultados.

        Args:
            results (List[List[str]]): Lista de resultados del cifrado

        Returns:
            Dict: Análisis de la distribución
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
        Genera gráficos para visualizar los resultados.

        Args:
            analysis (Dict): Resultados del análisis
            timestamp (str): Marca de tiempo
        """
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

        plt.figure(figsize=(12, 6))
        avg_autocorr = np.zeros(10)
        for pos in positions:
            autocorr = analysis['position_stats'][pos]['autocorrelation']
            avg_autocorr += np.array(autocorr[:10])
        avg_autocorr /= len(positions)

        plt.plot(range(1, 11), avg_autocorr, 'r-', marker='o')
        plt.title('Autocorrelación Promedio')
        plt.xlabel('Lag')
        plt.ylabel('Correlación')
        plt.grid(True)
        plt.savefig(f"{self.plots_dir}/autocorrelation_{timestamp}.png")
        plt.close()

        plt.figure(figsize=(15, 8))
        words, counts = zip(*analysis['global_stats']['most_common'][:20])
        plt.bar(words, counts)
        plt.title('20 Palabras Más Frecuentes')
        plt.xticks(rotation=45, ha='right')
        plt.ylabel('Frecuencia')
        plt.tight_layout()
        plt.savefig(f"{self.plots_dir}/word_distribution_{timestamp}.png")
        plt.close()

        # Nuevo gráfico: Distribución de p-values
        plt.figure(figsize=(12, 6))
        p_values = [analysis['position_stats'][p]['p_value'] for p in positions]
        plt.hist(p_values, bins=20, edgecolor='black')
        plt.title('Distribución de P-values')
        plt.xlabel('P-value')
        plt.ylabel('Frecuencia')
        plt.grid(True)
        plt.savefig(f"{self.plots_dir}/pvalue_distribution_{timestamp}.png")
        plt.close()

    def print_detailed_results(self, analysis: Dict, timestamp: str):
        """
        Imprime resultados detallados del análisis.

        Args:
            analysis (Dict): Resultados del análisis
            timestamp (str): Marca de tiempo
        """
        print("\n" + "="*50)
        print("ANÁLISIS DETALLADO DE RESULTADOS")
        print("="*50)

        # Estadísticas globales
        print("\n1. ESTADÍSTICAS GLOBALES")
        print("-"*30)
        print(f"Total de pruebas ejecutadas: {self.n_tests}")
        print(f"Pruebas exitosas: {analysis['global_stats']['total_words'] // len(self.test_seed)}")
        print(f"Palabras únicas totales: {analysis['global_stats']['unique_words']}")
        print(f"Frecuencia promedio: {analysis['global_stats']['average_frequency']:.2f}")

        # Estadísticas de la distribución global
        stats = analysis['global_stats']['word_frequency_stats']
        print("\nEstadísticas de frecuencia de palabras:")
        print(f"- Media: {stats['mean']:.2f}")
        print(f"- Desviación estándar: {stats['std_dev']:.2f}")
        print(f"- Mediana: {stats['median']:.2f}")
        print(f"- Asimetría: {stats['skewness']:.2f}")
        print(f"- Curtosis: {stats['kurtosis']:.2f}")

        # Análisis de reversibilidad
        print("\n2. ANÁLISIS DE REVERSIBILIDAD")
        print("-"*30)
        rev_stats = analysis['reversibility_analysis']
        print(f"Tests realizados: {rev_stats['total_tests']}")
        print(f"Reversiones exitosas: {rev_stats['successful_reversals']}")
        print(f"Reversiones fallidas: {rev_stats['failed_reversals']}")
        print(f"Tasa de éxito: {(rev_stats['successful_reversals']/rev_stats['total_tests'])*100:.2f}%")

        if rev_stats['failed_reversals'] > 0:
            print("\nDETALLE DE FALLOS:")
            for detail in rev_stats['detailed_results'][:5]:  # Primeros 5 fallos
                if not detail['is_reversible']:
                    print(f"- Diferencias encontradas: {len(detail['differences'])}")
                    for diff in detail['differences']:
                        print(f"  Posición {diff['position']}: {diff['original']} -> {diff['got']}")

        # Análisis por posición
        print("\n3. ANÁLISIS POR POSICIÓN")
        print("-"*30)
        for pos in range(len(self.test_seed)):
            stats = analysis['position_stats'][pos]
            print(f"\nPosición {pos}:")
            print(f"- Entropía: {stats['entropy']:.4f} bits")
            print(f"- P-value: {stats['p_value']:.4f}")
            print(f"- Chi-square: {stats['chi_square']:.4f}")
            print(f"- Palabras únicas: {stats['unique_words']}")
            print(f"- Media: {stats['mean']:.2f}")
            print(f"- Desviación estándar: {stats['std_dev']:.2f}")
            print("- Palabras más frecuentes:")
            for word, count in stats['most_common'][:5]:
                print(f"  * '{word}': {count} veces")
            print("- Palabras menos frecuentes:")
            for word, count in stats['least_common'][:3]:
                print(f"  * '{word}': {count} veces")
            print(f"- Autocorrelación (lag-1): {stats['autocorrelation'][0]:.4f}")

            dist_stats = stats['distribution_stats']
            print("- Estadísticas de distribución:")
            print(f"  * Asimetría: {dist_stats['skewness']:.4f}")
            print(f"  * Curtosis: {dist_stats['kurtosis']:.4f}")

        # Análisis de patrones
        print("\n4. ANÁLISIS DE PATRONES")
        print("-"*30)
        print("Autocorrelaciones promedio por posición:")
        avg_autocorr = np.zeros(10)
        for pos in range(len(self.test_seed)):
            avg_autocorr += np.array(analysis['position_stats'][pos]['autocorrelation'])
        avg_autocorr /= len(self.test_seed)
        for lag, corr in enumerate(avg_autocorr, 1):
            print(f"Lag-{lag}: {corr:.4f}")

        # Palabras más y menos frecuentes globales
        print("\n5. DISTRIBUCIÓN DE PALABRAS")
        print("-"*30)
        print("Palabras más frecuentes:")
        for word, count in analysis['global_stats']['most_common'][:10]:
            print(f"- '{word}': {count} veces")
        print("\nPalabras menos frecuentes:")
        least_common = sorted(analysis['global_stats']['most_common'], key=lambda x: x[1])[:10]
        for word, count in least_common:
            print(f"- '{word}': {count} veces")

        # Tiempo de ejecución
        if 'execution_stats' in analysis:
            print("\n6. ESTADÍSTICAS DE EJECUCIÓN")
            print("-"*30)
            print(f"Tiempo total de ejecución: {analysis['execution_stats']['total_time']:.2f} segundos")
            print(f"Timestamp: {analysis['execution_stats']['timestamp']}")

        # Información de archivos generados
        print("\n7. ARCHIVOS GENERADOS")
        print("-"*30)
        print(f"Directorio de resultados: {self.results_dir}")
        print(f"Gráficos guardados en: {self.plots_dir}")
        print(f"Archivo de análisis: analysis_{timestamp}.json")

    def analyze(self) -> Dict:
        """
        Realiza el análisis completo y devuelve los resultados.

        Returns:
            Dict: Resultados del análisis
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        start_time = time.time()

        print(f"\nIniciando análisis con {self.n_tests} pruebas...")

        # Generar contraseñas y ejecutar pruebas
        passwords = self.generate_passwords()
        with mp.Pool() as pool:
            results = list(tqdm(
                pool.imap(self.run_cipher, passwords),
                total=self.n_tests,
                desc="Procesando cifrados"
            ))

        # Filtrar resultados válidos
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
        test_pairs = list(zip(passwords_valid[:100], results_valid[:100]))

        for password, result in tqdm(test_pairs, desc="Verificando reversibilidad"):
            rev_test = self.test_reversibility(result, password)
            reversibility_results.append(rev_test)

        # Estadísticas de reversibilidad
        reversibility_stats = {
            "total_tests": len(reversibility_results),
            "successful_reversals": sum(1 for r in reversibility_results if r["success"] and r["is_reversible"]),
            "failed_reversals": sum(1 for r in reversibility_results if r["success"] and not r["is_reversible"]),
            "errors": sum(1 for r in reversibility_results if not r["success"]),
            "detailed_results": reversibility_results
        }

        analysis["reversibility_analysis"] = reversibility_stats

        # Generar visualizaciones
        self.generate_plots(analysis, timestamp)

        # Guardar resultados
        results_file = os.path.join(self.results_dir, f"analysis_{timestamp}.json")
        with open(results_file, 'w') as f:
            json.dump(analysis, f, indent=2, default=str)

        # Calcular tiempo total
        total_time = time.time() - start_time
        analysis['execution_stats'] = {
            'total_time': total_time,
            'timestamp': timestamp
        }

        # Mostrar resultados detallados
        self.print_detailed_results(analysis, timestamp)

        return analysis


def main():
    """
    Función principal que procesa los argumentos de línea de comandos y ejecuta el análisis.
    """
    parser = argparse.ArgumentParser(description='Analizador mejorado de cifrado')
    parser.add_argument('--script', default='./scypher.sh',
                      help='Ruta al script de cifrado (default: ./scypher.sh)')
    parser.add_argument('--tests', type=int, default=10000,
                      help='Número de pruebas a realizar (default: 10000)')
    parser.add_argument('--debug', action='store_true',
                      help='Activa el modo debug')

    args = parser.parse_args()

    analyzer = EnhancedAnalyzer(
        bash_script_path=args.script,
        n_tests=args.tests,
        debug=args.debug
    )

    try:
        results = analyzer.analyze()
        print(f"\nAnálisis completado. Resultados guardados en: {analyzer.results_dir}")
    except Exception as e:
        print(f"Error durante el análisis: {str(e)}")
        if args.debug:
            raise

if __name__ == "__main__":
    main()
