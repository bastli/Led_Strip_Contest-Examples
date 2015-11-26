# Led_Strip_Contest-Examples
Here you can find example code for the Bastli Led Strip Contest 2015/2016 (http://bastli.ch/contest). You might use it for reference or as a starting point for your code.

If you have working code in some funny programming language like Haskell, please make a merge request.

## TouchDesigner ##
This Windows VJ software has very broad capabilities for interactive performances. It is based on a realtime data-graph approach, meaning you can interconnect Audio, Textures, Images, UI, and 3D in one consisting and fast way. On top of that you can script everything with Python. You get a non-commercial version of TouchDesigner at https://www.derivative.ca/.

Just start the `touchdesigner/main.toe` file and it should work.

## C ##
The C example can be compiled with:
* ```bash gcc -std=gnu99 -pedantic *.c -lm -o app```
	The `-lm` switch is required for the wavefunction, which uses `sin(x)`
* ```bash clang -pedantic -std=gnu99 *.c -lm -o app```
* ```bash mingw32-gcc *.c -lwsock32 -lm -pedantic -std=gnu99 -o app```
* Visual Studio has not been tested yet. May very well need some love.

### Documentation ###
Documentation is available through doxygen.
```bash
cd c/
doxygen doxyfile
```
(Or alternatively just read the headerfiles)

## D ##
Compile with
```bash
dmd2 main.d barco/*.d -ofapp
```
Or any other D-Compiler(See <http://wiki.dlang.org/Compilers>)
