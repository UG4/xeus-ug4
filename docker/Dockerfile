FROM jupyter/minimal-notebook@sha256:ab2b9adef7bde04d36aa6882925a4b63463af20a0eea644472637ba64a4a78f2 AS modsim

ARG HOME=/home/jovyan
ENV PATH=$PATH:${HOME}/ughub
ENV XEUS_ENV=xeus-ug4-env 

# Install octave on top of jupyter/minimal-notebook
USER root
RUN apt-get update \
    && apt-get install -y \
    cmake \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER jovyan
RUN pip install --upgrade pip && pip install sympy numpy matplotlib
WORKDIR ${HOME}/.jupyter
RUN echo -e "c.NotebookApp.password = u'' \nc.NotebookApp.ip = '*' \nc.NotebookApp.token=''" >> jupyter_notebook_config.py 


# Installing ug4 as mentioned in README of git repo
USER root 
WORKDIR ${HOME}
RUN git clone https://github.com/UG4/ughub 
WORKDIR ${HOME}/ug4
RUN ughub init && \
    echo "source $HOME/ug4/ugcore/scripts/shell/ugbash">>${HOME}/.bashrc && \
    echo "export PATH=$PATH:$HOME/ughub">>${HOME}/.bashrc && \
    source ${HOME}/.bashrc && \
    ughub install Examples 
WORKDIR ${HOME}/ug4/build
RUN cmake -DCMAKE_BUILD_TYPE=Release .. && \
    cmake -DConvectionDiffusion=ON . && \
    cmake -DDIM="2;3" -DCPU=1 . && \
    make -j6

# Settings up conda env and installing xeus-ug4 kernel
RUN conda create -y -n xeus-ug4-env
ENV PATH /opt/conda/envs/${XEUS_ENV}/bin:$PATH
ENV CONDA_DEFAULT_ENV ${XEUS_ENV}
ENV UG4_ROOT /home/jovyan/ug4
SHELL ["conda", "run", "--no-capture-output", "-n", "xeus-ug4-env", "/bin/bash", "-c"]
RUN conda env list && \
    conda install -n ${XEUS_ENV} -y -c conda-forge cmake cppzmq xwidgets nlohmann_json xtl xeus-cling xeus==0.25 jupyterlab && \
    conda install -n ${XEUS_ENV} -y -c anaconda jupyter && \ 
    conda list
RUN conda env list && \
    echo $UG4_ROOT && \
    git clone https://github.com/UG4/xeus-ug4.git ${HOME}/xeus-ug4 && \
    mkdir ${HOME}/xeus-ug4/build && cd ${HOME}/xeus-ug4/build && \
    cmake -D CMAKE_INSTALL_PREFIX=$CONDA_PREFIX .. && \
    make && \
    make install

# Entering workdir and installing new xeus-UG4 kernel for user jovyan, s.t. jupyter is aware of new kernel in other conda env
USER jovyan
RUN jupyter kernelspec install --user /opt/conda/envs/xeus-ug4-env/share/jupyter/kernels/ug4_kernel
WORKDIR /home/jovyan
