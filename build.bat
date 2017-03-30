xcopy /y/d input\*.js source\js\3p\

coffee -o source\js -c source\coffee

xcopy /y/d source\Sandbox.html output\
xcopy /e/y/d source\js\3p\* output\js\3p\
xcopy /e/y/d source\js\src\* output\js\src\
