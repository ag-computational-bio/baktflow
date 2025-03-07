from setuptools import setup, find_packages,find_namespace_packages

setup(
    name="baktflow",
    version="0.1.0",
  packages=find_packages(include=['baktflow', 'baktflow.*']) + find_namespace_packages(include=['nextflow_interface', 'nextflow_interface.*']),
    include_package_data=True,
    package_data={
        'nextflow_interface': ['**/*.yaml', '**/*.nf','**/*.config'],
        'baktflow': ['**/*.py'],  
    },
    install_requires=[
        'nextflow',
        'pandas>=1.0.0',
        'jinja2>=2.10',
        'plotly>=4.0.0',
    ],
    python_requires='>=3.6',
    entry_points={
        'console_scripts': [
            'baktflow = baktflow.CLI:main',
        ],
    },

)