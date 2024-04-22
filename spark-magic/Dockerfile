FROM python:3.9-bookworm

# Env variables
ENV NVM_HOME=/root/.nvm
ENV SPARK_HOME=/opt/spark

# Update deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      sudo \
      curl \
      unzip \
      build-essential \
      software-properties-common \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install nodejs for lab
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN . "$NVM_HOME/nvm.sh" && nvm install 20


# Export paths
ENV PATH=$PATH:$NVM_HOME/versions/node/v20/bin

# Install jupyterlab
RUN pip install jupyterlab
RUN pip install pyspark==3.5.1
RUN pip install sparkmagic

# Install extensions
# RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension 
RUN pip install pip install ipywidgets

RUN echo pip show sparkmagic

# Install wrapper kernels
RUN jupyter-kernelspec install $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkkernel
RUN jupyter-kernelspec install $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/pysparkkernel

# Copy config file
RUN mkdir -p /home/lab/.spakmagic
COPY config.json /home/lab/.spakmagic

# Entrypoint
COPY ./entrypoint.sh .
ENTRYPOINT ["./entrypoint.sh"]