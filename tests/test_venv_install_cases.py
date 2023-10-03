class CasesVenvInstallRequirementstxt:
    def case_pypi(self):
        requirements = [
            "python-json-logger==2.0.7",
        ]

        return {"requirements.txt": "\n".join(requirements)}

    def case_git(self):
        requirements = [
            "python-json-logger @ git+https://github.com/madzak/python-json-logger@v2.0.7",
        ]

        return {"requirements.txt": "\n".join(requirements)}

    def case_git_token(self, create_test_credentials: None):
        requirements = ["python-json-logger @ git+https://${TEST_TOKEN}@github.com/madzak/python-json-logger@v2.0.7"]

        return {"requirements.txt": "\n".join(requirements)}

    def case_git_user_pass(self, create_test_credentials: None):
        requirements = [
            "python-json-logger @ git+https://${TEST_USER}:${TEST_PASS}@github.com/madzak/python-json-logger@v2.0.7"
        ]

        return {"requirements.txt": "\n".join(requirements)}


class CasesVenvInstallDevRequirementstxt:
    def case_pypi_dev(self):
        requirements = [
            "python-json-logger==2.0.7",
        ]

        dev_requirements = [
            "-r requirements.txt",
            "numpy==1.26.0",
        ]

        files = {
            "requirements.txt": "\n".join(requirements),
            "dev-requirements.txt": "\n".join(dev_requirements),
        }
        return files

    def case_git_dev(self):
        requirements = [
            "python-json-logger @ git+https://github.com/madzak/python-json-logger@v2.0.7",
        ]

        dev_requirements = [
            "-r requirements.txt",
            "numpy==1.26.0",
        ]

        files = {
            "requirements.txt": "\n".join(requirements),
            "dev-requirements.txt": "\n".join(dev_requirements),
        }
        return files

    def case_git_token_dev(self, create_test_credentials: None):
        requirements = [
            "python-json-logger @ git+https://${TEST_TOKEN}@github.com/madzak/python-json-logger@v2.0.7",
        ]

        dev_requirements = [
            "-r requirements.txt",
            "numpy==1.26.0",
        ]

        files = {
            "requirements.txt": "\n".join(requirements),
            "dev-requirements.txt": "\n".join(dev_requirements),
        }
        return files

    def case_git_user_pass_dev(self, create_test_credentials: None):
        requirements = [
            "python-json-logger @ git+https://${TEST_USER}:${TEST_PASS}@github.com/madzak/python-json-logger@v2.0.7",
        ]

        dev_requirements = [
            "-r requirements.txt",
            "numpy==1.26.0",
        ]

        files = {
            "requirements.txt": "\n".join(requirements),
            "dev-requirements.txt": "\n".join(dev_requirements),
        }
        return files
