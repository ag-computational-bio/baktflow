from setuptools import setup, find_packages

setup(
    name="baktflow",
    version="0.1.0",
    description="Bacterial ",
    long_description=open('README.md').read(),
    long_description_content_type="text/markdown",
    author="",
    author_email="hellonaouel@gmail.com",
    
    packages=find_packages(),
   
    include_package_data=True,
    package_data={
        'baktflow': ['nextflow/*']
    },
    install_requires=[
        "nextflow"
        # Add other dependencies
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
    python_requires='>=3.6',
)