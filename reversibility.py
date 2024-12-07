import subprocess
import random
import string
import statistics

class ReversibilityTester:
    def __init__(self, bash_script_path, original_seed):
        """
        Initialize the reversibility tester

        :param bash_script_path: Path to the bash encryption script
        :param original_seed: List of original seed words
        """
        self.bash_script_path = bash_script_path
        self.original_seed = original_seed

    def generate_random_password(self, length=12):
        """
        Generate a random password

        :param length: Length of the password
        :return: Randomly generated password
        """
        # Mix of letters (upper and lower), digits, and punctuation
        characters = string.ascii_letters + string.digits + string.punctuation
        return ''.join(random.choice(characters) for _ in range(length))

    def run_encryption(self, password, words):
        """
        Run encryption using the bash script

        :param password: Password to use for encryption
        :param words: Words to encrypt
        :return: Encrypted words
        """
        cmd = [self.bash_script_path, "-p", password] + words
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout.strip().split()

    def test_reversibility(self, num_tests=1000):
        """
        Test the reversibility of the encryption process

        :param num_tests: Number of tests to run
        :return: Dictionary with test results
        """
        results = {
            'total_tests': num_tests,
            'successful_reversals': 0,
            'failed_reversals': 0,
            'failed_passwords': []
        }

        for _ in range(num_tests):
            # Generate a random password
            password = self.generate_random_password()

            try:
                # Encrypt the original seed
                encrypted_seed = self.run_encryption(password, self.original_seed)

                # Try to decrypt back to the original seed
                decrypted_seed = self.run_encryption(password, encrypted_seed)

                # Check if decryption matches original seed
                if decrypted_seed == self.original_seed:
                    results['successful_reversals'] += 1
                else:
                    results['failed_reversals'] += 1
                    results['failed_passwords'].append(password)

            except Exception as e:
                results['failed_reversals'] += 1
                results['failed_passwords'].append(password)

        return results

    def generate_report(self, results):
        """
        Generate a detailed report of the reversibility test

        :param results: Results dictionary from test_reversibility
        """
        print("\n--- Reversibility Test Report ---")
        print(f"Total Tests: {results['total_tests']}")
        print(f"Successful Reversals: {results['successful_reversals']} " +
              f"({results['successful_reversals']/results['total_tests']*100:.2f}%)")
        print(f"Failed Reversals: {results['failed_reversals']} " +
              f"({results['failed_reversals']/results['total_tests']*100:.2f}%)")

        if results['failed_reversals'] > 0:
            print("\nSample of Failed Passwords:")
            for pw in results['failed_passwords'][:10]:
                print(pw)

def main():
    # Original seed words (replace with your actual seed)
    original_seed = [
        "ribbon", "slight", "frog", "oxygen", "range",
        "slam", "destroy", "dune", "fossil", "slow",
        "decrease", "primary", "hint", "loan", "limb",
        "palm", "act", "reward", "foot", "deposit",
        "response", "fashion", "under", "sail"
    ]

    # Path to your bash script
    bash_script_path = './script.sh'

    # Create tester
    tester = ReversibilityTester(bash_script_path, original_seed)

    # Run reversibility test
    results = tester.test_reversibility(num_tests=1000)

    # Generate and print report
    tester.generate_report(results)

if __name__ == "__main__":
    main()
