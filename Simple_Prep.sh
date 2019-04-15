#!/bin/bash

set -e

function errorout() {
    echo
    echo "ERROR: $@" >&2
    echo "Exiting"
    echo
    kill -INT $$
}

# Check if FSL is available
if [ ! $(command -v bet) ]; then
    if [ -f /etc/fsl/fsl.sh ]; then
        source /etc/fsl/fsl.sh
    else
        errorout "No bet: Make sure an FSL version - https://fsl.fmrib.ox.ac.uk/ - is installed and available."
    fi
fi
echo "FSL bet is available"

# Check if first models are available

if ! /bin/ls $FSLDIR/data/first/models* >/dev/null; then
    errorout "No first data found (fsl-first-data package on Debians)"
fi
echo "FSL first data found"

if ! /bin/ls $FSLDIR/data/standard/MNI152_T1_1mm.nii.gz >/dev/null; then
    errorout "No FSL MNI templates found (fsl-mni152-templates package on Debians)"
fi
echo "FSL MNI templates found"


# Check if curl is available
[ ! $(command -v curl) ] && echo "No curl: Make sure a version of curl is installed and available." && kill -INT $$
echo "curl is available"

# Setup standalone python environment
echo "Setting up standalone conda Python environment"

if [ ! -e miniconda ]; then
    echo "Downloading miniconda"
    if [ `uname` == 'Darwin' ]; then
        curl -sSL -o miniconda.sh http://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
    else
        curl -sSL -o miniconda.sh http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
    fi

    echo "Setting up miniconda"
    chmod +x miniconda.sh
    ./miniconda.sh -b -p $PWD/miniconda
    rm miniconda.sh
fi
PATH=$PWD/miniconda/bin:$PATH
echo "Creating and activating versioned Python environment"
if [ ! -e miniconda/envs/bh_demo/bin/nipype_display_crash ]; then
    if [ -e miniconda/envs/bh_demo/ ]; then
        rm -rf miniconda/envs/bh_demo
    fi
    if [ ${#PWD} -gt 36 ]; then
        echo "---- BEGIN SIMPLE_PREP SCRIPT WARNING ----

If you receive a PaddingError with the following command, your current
working directory path length ${#PWD} is longer than 36 chars. Move to
a working directory path that is at most 36 chars. Run:

echo \${#PWD}

to check.

---- END SIMPLE_PREP SCRIPT WARNING ----"
    fi
    conda env create -f environment.yml
    conda clean -tipsy
fi

# install niflow-simple-workflow
PATH=$PWD/miniconda/envs/bh_demo/bin:$PATH
cd "$PWD"/niflow-simple-workflow/package &&\
python setup.py install
cd -
# optional arguments to run the demo workflow (not mandatory)
if [ "$1" == "test" ]; then
    
    niflow-simple-workflow --key 11an55u9t2TAf0EV2pHN0vOd8Ww2Gie-tHp9xGULh_dA -n 1 \
      -o "$PWD"/niflow-simple-workflow/test/output && \
    python niflow-simple-workflow/test/scripts/check_output.py --ignoremissing
fi
if [ "$1" == "replay" ]; then
    niflow-simple-workflow --key 11an55u9t2TAf0EV2pHN0vOd8Ww2Gie-tHp9xGULh_dA \
      -o "$PWD"/niflow-simple-workflow/test/output && \
    python niflow-simple-workflow/test/scripts/check_output.py
fi

export PATH
