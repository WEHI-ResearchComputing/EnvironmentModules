* R packages can't be statically compiled, because the dependency libraries like libhdf5.so are dynamically linked
* Dynamically loading all dependencies is very difficult, because we would basically have to re-implement the `dlopen` algorithm in R
* Using -rpath will allow using modules without restarting R, but also won't break if the modules move
