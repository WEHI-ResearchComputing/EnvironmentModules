readme
================

The EnvironmentModules package is an R front-end for the [Environment
Modules](https://modules.readthedocs.io/en/latest/index.html) project,
which offers a way to load and unload packages, and is commonly used on
shared HPC (High Performance Computing) environments.

``` r
library(EnvironmentModules)
```

## Listing Modules

You can list the available modules:

``` r
module_avail()
#> <cli_ansi_string>
#> [1] ------------------- [1;94m/stornext/System/data/modulefiles/tools[0m --------------------                          
#> [2] [4mapptainer/1.0.0[0m              [4mmpich-slurm/3.3.2[0m                   wine/7.17                     
#> [3] apptainer/1.1.0              mpich-slurm/3.4.1                   [4mzeromq/4.3.4[0m                                
#> [4] aspera/3.5.4                 mpich-slurm/3.4.2                   [4mzstd/1.5.0[0m                                  
#> [5] aspera/3.9.1                 [4mmpich/3.3[0m                                                                       
#> [6] [4maspera/3.9.6[0m                 mpich/3.3.2                                                                     
#> [7] awscli/1.16py2.7             [4mncftp/3.2.6[0m                                                                     
#> [8] awscli/1.16py3.7             nextflow/22.04.5                                                                              
#> [9] awscli/1.22.89               [4mnextflow/22.10.4[0m                                                                
#> [10] awscli/2.1.25                [4mninja/1.10.0[0m                                                                   
#> [11] [4mawscli/2.5.2[0m                 [4mnmap-ncat/7.91[0m                                                   
#> [12] [4maxel/2.17.10[0m                 nodejs/10.24.1                                                                 
#> [13] bazel/0.26.1                 nodejs/16.19.0                                                                               
#> [14] [4mbazel/1.2.1[0m                  [4mnodejs/17.9.1[0m                                                    
#> [15] binutils/2.35.2-gcc-4.8.5    [4mocl-icd/2.3.1[0m                                                                  
#> [16] binutils/2.35.2-gcc-9.1.0    [4moctave/6.4.0-gcc11.1.0[0m                                                         
#> [17] [4mcluster-utils/18.08.1[0m        [4moneMKL/2022.1.0.223[0m                                              
#> [18] [4mcmake/3.25.1[0m                 [4mopenBLAS/0.3.6-gcc-9.1.0[0m                                         
#> [19] [4mCUnit/2.1-3[0m                  openBLAS/0.3.21-gcc-11.1.0                                                     
....
```

You can filter to only modules starting with some prefix:

``` r
module_avail("python")
#> <cli_ansi_string>
#> [1] ----------------- [1;94m/stornext/System/data/modulefiles/bioinf/its[0m -----------------                                                                       
#> [2] [1mpython[22m/2.7.18  [1mpython[22m/3.5.3        [1mpython[22m/3.7.0   [1mpython[22m/3.8.3  [1mpython[22m/3.9.5                 
#> [3] [1mpython[22m/3.5.1   [1mpython[22m/3.6.5-intel  [1mpython[22m/3.7.13  [4m[1mpython[22m/3.8.8[0m  [1mpython[22m/3.10.4  
#> [4]                                                                                                                                                                         
#> [5] Key:                                                                                                                                                                    
#> [6] [1;94mmodulepath[0m  [4mdefault-version[0m
```

## Loading and Unloading Modules

Load modules using `module_load()`!

``` r
module_load("python/3")
#> ✔ Successfully loaded python/3
```

If you’ve already loaded a module, you will be notified:

``` r
module_load("python/3")
#> ℹ Nothing to do. This module was probably already loaded. Use module_list() to verify.
```

You can unload a module using the corresponding `module_unload()`:

``` r
module_unload("python/3")
#> ✔ Successfully unloaded python/3
```

## Listing Loaded Modules

You can list modules that have been already loaded with `module_list()`:

``` r
module_load("python/3")
#> ✔ Successfully loaded python/3
module_list()
#> <cli_ansi_string>
#> [1] Currently Loaded Modulefiles:   
#> [2]  1) [4mpython/3.8.8[0m  
#> [3]                                 
#> [4] Key:                            
#> [5] [4mdefault-version[0m
```

## Linking Shared Libraries

Although `module_load()` will add a module’s libraries to your
`LD_LIBRARY_PATH`, which will allow you to compile packages against
them, R will not necessarily be able to actually run packages that use
these libraries.

For example, let’s say we want to use the `hdf5r` package, which depends
on the `hdf5` library package. We don’t have `hdf5` loaded, so it will
fail:

``` r
install.packages("hdf5r", quiet = TRUE)
#> Error in install.packages : Updating loaded packages
```

We can resolve this by loading the appropriate module. Firstly, we need
to find out what the module is called:

``` r
module_avail("hdf5")
#> <cli_ansi_string>
#> [1] ------------------- [1;94m/stornext/System/data/modulefiles/tools[0m --------------------                                                                                     
#> [2] [4m[1mhdf5[22m-mpich/1.10.5_3.3[0m                                                                                                                                    
#> [3]                                                                                                                                                                                       
#> [4] ----------------- [1;94m/stornext/System/data/modulefiles/bioinf/its[0m -----------------                                                                                     
#> [5] [1mhdf5[22m/1.8.16  [1mhdf5[22m/1.8.20  [1mhdf5[22m/1.8.21  [1mhdf5[22m/1.10.5  [4m[1mhdf5[22m/1.12.1[0m  [1mhdf5[22m/1.12.2  
#> [6]                                                                                                                                                                                       
#> [7] Key:                                                                                                                                                                                  
#> [8] [1;94mmodulepath[0m  [4mdefault-version[0m
```

Then loading the module:

``` r
module_load("hdf5/1.12.2")
#> ✔ Successfully loaded hdf5/1.12.2
```

Now let’s try again:

``` r
install.packages("hdf5r", quiet = TRUE)
#> Error in install.packages : Updating loaded packages
```

Finally, we can load the package itself… or can we?

``` r
library(hdf5r)
```

As alluded to above, R doesn’t actually load every new library that
becomes available in the environment. Rather it uses “load-time
linking”, which is where the libraries it links to are fixed at the time
you start R. Now, you can resolve the above error by closing R, loading
the module, and then restarting R, but this can be quite annoying.

Fortunately, R also supports “run-time linking”, which you can enable by
loading a module with the `link_libs=TRUE` argument:

``` r
module_unload("hdf5/1.12.2")
#> ✔ Successfully unloaded hdf5/1.12.2
module_load("hdf5/1.12.2", link_libs=TRUE)
#> ✔ Successfully loaded hdf5/1.12.2
```

``` r
library(hdf5r)
```

It worked!

If you are interested in the theory underlying what is happening here,
you might find this explanation of linking on Linux helpful:
<https://techblog.rosedu.org/library-management.html>.

## Other Commands

This package also supports the following.

`module_swap()` unloads the first module and loads the second:

``` r
module_swap("hdf5/1.12.2", "hdf5/1.10.5")
```

`module_purge()` unloads all modules:

``` r
module_purge()
```

## Advanced Commands

If you want to use a feature of Environment Modules that does not (yet)
have a dedicated function, you can use the advanced functions
`get_module_code` or `get_module_output`.

If you want to run a command that doesn’t edit the modules, but only
shows output, run `get_module_output`

``` r
get_module_output(c("show", "hdf5"))
#> <cli_ansi_string>
#> [1] -------------------------------------------------------------------                                                                                             
#> [2] [1m/stornext/System/data/modulefiles/bioinf/its/hdf5/1.12.1[22m:                                                                                        
#> [3]                                                                                                                                                                 
#> [4] [92mmodule-whatis[0m   {HDF5 is a unique technology suite that makes possible the management of extremely large and complex data collections. (v1.12.1)} 
#> [5] [92mconflict[0m    hdf5                                                                                                                                   
#> [6] [92mprepend-path[0m    PATH /stornext/System/data/apps/hdf5/hdf5-1.12.1/bin                                                                               
#> [7] [92mprepend-path[0m    CPATH /stornext/System/data/apps/hdf5/hdf5-1.12.1/include                                                                          
#> [8] [92mprepend-path[0m    LD_LIBRARY_PATH /stornext/System/data/apps/hdf5/hdf5-1.12.1/lib                                                                    
#> [9] [92mprepend-path[0m    LIBRARY_PATH /stornext/System/data/apps/hdf5/hdf5-1.12.1/lib                                                                       
#> [10] [92mprepend-path[0m   MANPATH :/stornext/System/data/apps/hdf5/hdf5-1.12.1/share/man                                                                    
#> [11] -------------------------------------------------------------------
```

If the module does edit the modules, use `get_module_code()`, and
evaluate the result:

``` r
get_module_code("reload") |> eval()
#> NULL
```

## FAQ

> Environment Modules [supports loading modules in R since version
> 4.0.0!](https://modules.readthedocs.io/en/latest/index.html) What is
> the point of this package?

This is true, and actually this package is just a wrapper around that
core functionality. You *need* Modules version 4.0.0 or above to run
this package. The main advantages of using this wrapper are the nicer
function interfaces, and the ability to automatically link R to newly
loaded libraries.

> I’m getting the error “Could not detect an Environment Modules
> installation”, but I know that Environment Modules is installed on my
> system. What do I do?

First, in a bash terminal where the `module` command works correctly,
run `which modulecmd`. Then in R, run
\`Sys.setenv(MODULES_CMD=“</path/to/modulecmd>”), putting the output
from the previous step as the argument value. Then everything should
work!
