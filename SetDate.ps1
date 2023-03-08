#Поиск файлов с картинками в порядке сортировки по именам
#Установка параметров съемки последовательно на дату в прошлом
#------------------------------------------------------------------
#Функции
#------------------------------------------------------------------
#Проверяет существование файла
function IsFileExists([string]$pathToTest) {
    return Test-Path  -PathType Leaf -Path $pathToTest
}
#------------------------------------------------------------------
#Начало программы
#------------------------------------------------------------------
#Первичные настройки
#Новая дата съемки в формате 1998:12:31
$newCaptureDate="2004:05:15"
#Час м минута, от которых будут считаться новые часы и минуты (обычно не нужно изменять)
$startCaptureHour=12 # нужно чтобы конечный час не стал больше 23
$startCaptureMin=1 # от 1 до 58

Write-Host 'Starting .....'
#Начальные значения переменных
$numOfFiles=0 #найдено файлов
#Текущий путь запуска скрипта. В нем идет поиск exiftool.exe и файлов с картинками
$cur_path=$PSScriptRoot
#Проверяем, что есть exiftool
if (-not((IsFileExists($cur_path+'\exiftool.exe')))) {
    #Окончание программы
    Write-Host -ForegroundColor Red 'ERROR! exiftool.exe not found in current folder'
    Exit
}
#------------------------------------------------------------------
#Основной текст программы
#------------------------------------------------------------------
#Просматриваем текущую папку и берем по очереди файлы картинок
#обход файлов
$FileList= Get-ChildItem -Path $cur_path -Force -ErrorAction SilentlyContinue -File -Name -Include @("*.psd", "*.jpeg", "*.jpg", "*.arw")
foreach ($FileSpec in $FileList) {
    #перебор файлов
    #$FileSpec - имя очередного файла из выборки
    #Проверяем существование файла
    if (-not (IsFileExists($FileSpec))) { # почему-то его не оказалось на месте
        Continue 
    }
    $numOfFiles=$numOfFiles+1
    write-host 'Found file : ' -NoNewline
    write-host -ForegroundColor Green $FileSpec -NoNewline
    #Формирование строки с параметрами
    $newCaptureHour=$startCaptureHour +[math]::Floor(($startCaptureMin+($numOfFiles-1))/60)
    $newCaptureHour=([String]$newCaptureHour).PadLeft(2, '0') #добавление ведущего нуля
    $newCaptureMin=$startCaptureMin+($numOfFiles-1)-[math]::Floor(($startCaptureMin+($numOfFiles-1))/60)*60
    $newCaptureMin=([String]$newCaptureMin).PadLeft(2, '0') #добавление ведущего нуля
    $commandString='-AllDates="'+$newCaptureDate+' '+$newCaptureHour+':'+$newCaptureMin+':00" '+ $FileSpec
    write-host ' set parameter: '$commandString
    # пример    -AllDates="1998:02:01 12:01:00"' IMG_199802.01.psd  
    #------------------------------------------------------------------
    #здесь вся работа происходит
    #------------------------------------------------------------------
    #Start-Process -FilePath  .\ffmpeg.exe  -ArgumentList $transcodeString -Wait -NoNewWindow -RedirectStandardError $ffmpegfilename
    Start-Process -FilePath  .\exiftool.exe  -ArgumentList $commandString -Wait -NoNewWindow

    #------------------------------------------------------------------
} #конец перебора файлов
write-host $numOfFiles 'picture files found in folder'
#
