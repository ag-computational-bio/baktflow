from setuptools import setup, find_packages

setup(
    name="baktflow",
    version="0.1.0",
    description="Bacterial ",
    long_description=open('README.md').read(),
    long_description_content_type="text/markdown",
    author="Oliver Schwengers",
    author_email="oliver.schwengers@cb.jlug.de",
    
    packages=find_packages(),
   
    include_package_data=True,
    package_data={
        'baktflow': [
            'nextflow_baktflow/setup.nf',
            'nextflow_baktflow/main.nf',
            'nextflow_baktflow/modules/*',
            'nextflow_baktflow/subworkflow/*',
        ]
    },
    install_requires=[
        'nextflow',
        'pandas>=1.0.0',
        'jinja2>=2.10',
        'plotly>=4.0.0',
    ],
    entry_points={
        'console_scripts': [
            'baktflow = baktflow.CLI:main',
        ],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.8',
)