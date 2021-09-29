# Toolbox to Mitigate Bias in AI

This repository contains the materials for the Toolbox to Mitigate Bias in AI tutorial.

## Pre-requisites

For this tutorial, we will be using the development version from GitHub of the [AIF360 Package](https://github.com/Trusted-AI/AIF360/tree/master/aif360/aif360-r).

You can install the development version on your machine or you can use Docker. Please follow the steps below to install. 



### 1) Installing on your machine


1.1) Install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("Trusted-AI/AIF360/aif360/aif360-r")
```


1.2) Install reticulate and check if you have miniconda installed. If you do, go to step 1.3.

``` r
install.packages("reticulate")
reticulate::conda_list()
```

If you get an error: `Error: Unable to find conda binary. Is Anaconda installed?`, please install miniconda

``` r
reticulate::install_miniconda()
```

If everything worked, you should get the message:

`* Miniconda has been successfully installed at '/home/rstudio/.local/share/r-miniconda'.`

You can double check:

```r
reticulate::conda_list()
```

You will get something like this:

``` 
          name                                                              python
1  r-miniconda                   /home/rstudio/.local/share/r-miniconda/bin/python
2 r-reticulate /home/rstudio/.local/share/r-miniconda/envs/r-reticulate/bin/python
```

1.3)  You can create a new conda env and then configure which version of Python to use:

``` r
reticulate::conda_create(envname = "r-test")
reticulate::use_miniconda(condaenv = "r-test", required = TRUE)
```

Check that everything is working `reticulate::py_config()`.

1.4)  Install aif360 dependencies

``` r
aif360::install_aif360(envname = "r-test")
```

Note: AIF360 is distributed as a Python package and so needs to be installed within a Python environment on your system. By default, the `install_aif360()` function attempts to install AIF360 within an isolated Python environment (“r-reticulate”).

This step should take a few minutes and the R session will restart.

1.5) Finally, load the aif360 functions

``` r
library(aif360)
reticulate::use_miniconda(condaenv = "r-test", required = TRUE)
load_aif360_lib()
``` 

The whole installation process should take about 15 minutes

### 2) Using Docker

Alternatively, you can Docker. Follow the steps below:

2.1) Install docker: [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)

2.2) Go to terminal and run:

Change the `yourpassword` to any password that you would like.
```
docker run -e PASSWORD=yourpassword --rm -p 8787:8787 gdequeiroz/north-conference
```

2.3) Open your browser and type: `localhost:8787` 

2.4) You will be prompted to sign-in to RStudio. Use the credentials: 

- Username:  rstudio
- Password: the one (yourpassword) you defined above

2.5) Finally, load the aif360 functions

``` r
library(aif360)
reticulate::use_miniconda(condaenv = "r-test", required = TRUE)
load_aif360_lib()
```

2.6) Run the scripts: `adversarial-debiasing-in-processing.R` and `reweighing-pre-processing.R`
