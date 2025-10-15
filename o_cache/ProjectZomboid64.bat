@setlocal enableextensions
@cd /d "%~dp0"
SET _JAVA_OPTIONS=

SET PZ_CLASSPATH=.\guava-23.0.jar;commons-compress-1.27.1.jar;commons-io-2.18.0.jar;istack-commons-runtime.jar;jassimp.jar;javacord-3.8.0-shaded.jar;javax.activation-api.jar;jaxb-api.jar;jaxb-runtime.jar;lwjgl.jar;lwjgl-natives-windows.jar;lwjgl-glfw.jar;lwjgl-glfw-natives-windows.jar;lwjgl-jemalloc.jar;lwjgl-jemalloc-natives-windows.jar;lwjgl-opengl.jar;lwjgl-opengl-natives-windows.jar;lwjgl_util.jar;sqlite-jdbc-3.27.2.1.jar;trove-3.0.3.jar;uncommons-maths-1.2.3.jar;imgui-binding-1.86.11-8-g3e33dde.jar;commons-codec-1.10.jar;javase-3.2.1.jar;totp-1.0.jar;core-3.2.1.jar;./

:: Rileva hardware del sistema
for /f "tokens=2 delims==" %%a in ('wmic OS get TotalVisibleMemorySize /value') do set /a total_mem=%%a/1024
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfCores /value') do set /a num_cores=%%a
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfLogicalProcessors /value') do set /a num_threads=%%a

:: Imposta memoria in base alla RAM disponibile
if %total_mem% GTR 16000 (
SET MEM_MAX=10240m
SET MEM_MIN=4096m
) else if %total_mem% GTR 12000 (
SET MEM_MAX=8192m
SET MEM_MIN=2048m
) else if %total_mem% GTR 8000 (
SET MEM_MAX=6144m
SET MEM_MIN=2048m
) else (
SET MEM_MAX=4096m
SET MEM_MIN=1024m
)

:: Imposta thread pool e GC in base a CPU
if %num_cores% LEQ 2 (
set GC_THREADS=1
set CONCURRENT_THREADS=1
set FJ_PARALLELISM=2
) else if %num_cores% LEQ 4 (
set GC_THREADS=2
set CONCURRENT_THREADS=2
set FJ_PARALLELISM=4
) else if %num_cores% LEQ 8 (
set GC_THREADS=4
set CONCURRENT_THREADS=2
set FJ_PARALLELISM=6
) else (
set GC_THREADS=6
set CONCURRENT_THREADS=3
set FJ_PARALLELISM=8
)

:: Avvia con impostazioni ottimizzate per multi-core
echo Avvio Project Zomboid con ottimizzazioni multi-core...
echo CPU: %num_cores% core, %num_threads% thread
echo RAM: %total_mem% MB (Allocati: %MEM_MAX%)
echo Thread concorrenti: %FJ_PARALLELISM%

".\jre64\bin\java.exe" -verbose:class -Djava.awt.headless=true -Dzomboid.steam=1 -Dzomboid.znetlog=1 -XX:-CreateCoredumpOnCrash -XX:-OmitStackTraceInFastThrow -XX:+UseZGC -XX:ZCollectionInterval=120 -XX:ConcGCThreads=%CONCURRENT_THREADS% -XX:+UnlockExperimentalVMOptions -XX:+AlwaysPreTouch -XX:+UseNUMA -XX:+DisableExplicitGC -Xmx%MEM_MAX% -Xms%MEM_MIN% -Djava.library.path=./win64/;./ -Dguava.library.path=. -Djogl.disable.openglcore=false -XX:+OptimizeStringConcat -Dzomboid.multithreading=true -Dzomboid.thread.model=worksteal -Dzomboid.thread.priority=high -Dzomboid.threadpool.size=%num_cores% -Djava.util.concurrent.ForkJoinPool.common.parallelism=%FJ_PARALLELISM% -cp %PZ_CLASSPATH% zombie.gameStates.MainScreenState %1 %2

IF %ERRORLEVEL% NEQ 0 (
echo Tentativo con impostazioni di memoria ridotte...
".\jre64\bin\java.exe" -verbose:class -Djava.awt.headless=true -Dzomboid.steam=1 -Dzomboid.znetlog=1 -XX:-CreateCoredumpOnCrash -XX:-OmitStackTraceInFastThrow -XX:+UseG1GC -Xmx3072m -Xms1024m -Djava.library.path=./win64/;./ -Dguava.library.path=. -Dzomboid.multithreading=true -Dzomboid.threadpool.size=2 -cp %PZ_CLASSPATH% zombie.gameStates.MainScreenState %1 %2
)

PAUSE