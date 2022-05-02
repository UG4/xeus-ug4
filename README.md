# xeus-ug4

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/UG4/xeus-ug4/master)

**xeus-ug4** is Jupyter kernel for UG4 based on the native implementation of the Jupyter protocol xeus.
**xeus-ug4** is early developer preview. Is is not suitable for general usage yet.  

## Usage

Launch the Jupyter notebook with 'jupyter notebook' or Jupyter lab with 'jupyter lab' and launch a new Jupyter notebook by selecting the **UG4 LUA**  kernel.


## Installation

Currently, only installation from source is available.

Conda dependencies:
```
$XEUS_ENV="xeus-ug4-env"
conda install -n ${XEUS_ENV} -y -c conda-forge cmake cppzmq xwidgets nlohmann_json xtl xeus-cling xeus==0.25 jupyterlab
conda install -n ${XEUS_ENV} -y -c anaconda jupyter
```

Install kernel:

```
mkdir build
cd build
cmake -D CMAKE_INSTALL_PREFIX=$CONDA_PREFIX ..
make
make install
```

Introduce jupyter to new kernel as mention here [ipython.readthedocs.io/](https://ipython.readthedocs.io/en/stable/install/kernel_install.html):
```
jupyter kernelspec install --user /opt/conda/envs/xeus-ug4-env/share/jupyter/kernels/ug4_kernel
```

## Documentation

Documentation is not available yet.

## Dependencies

xeus-ug4 depends on
```
cppzmq 
xwidgets 
nlohmann_json
xtl 
xeus-cling 
xeus==0.25 
jupyterlab
```
    

## License

This software is licensed under the BSD-3-Clause license. See the LICENSE file for details.
