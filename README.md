# xeus-ug4

**  xeus-ug4 is early developer preview and is not suitable for general usage yet ** 
'xeus-ug4' is Jupyter kernel for UG4 based on the native implementation of the Jupyter protocol xeus.

##Usage

Launch the Jupyter notebook with 'jupyter notebook' or Jupyter lab with 'jupyter lab' and launch a new SQL notebook by selecting the **UG4 LUA**  kernel.


## Installation

Currently, only installation from source is available.


conda create -n xeus-ug4-env
conda activate xeus-ug4-env
conda install cmake nlohmann_json xtl cppzmq xeus -c conda-forge

mkdir build
cd build
cmake -D CMAKE_INSTALL_PREFIX=$CONDA_PREFIX ..
make
make install

## Documentation

Documentation is not available yet.
Dependencies

xeus-ug4 depends on

    xeus
    nlohmann/json
    

## License

This software is licensed under the BSD-3-Clause license. See the LICENSE file for details.
