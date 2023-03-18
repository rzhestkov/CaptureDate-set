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
$startCaptureSec=5 # от 1 до 58. 5 - оптимальное значение
$SecAcuracy=1 # если "0", то прибаляет по минуте, если "1", то по 5 секунд
$OverwriteOriginal=0 # если "0", то оригинальные файлы будут сохранены рядом, с расширением вида "jpg_original", если не ноль, то оригинальные файлы будут перезаписаны
#------------------------------------------------------------------

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
if ($SecAcuracy -eq 0) { # сообщение
    write-host 'Capture time increment in files will be set by ' -NoNewline
    write-host -ForegroundColor Green '1 minute'
} elseif ($SecAcuracy -eq 1) {
    write-host 'Capture time increment in files will be set by ' -NoNewline
    write-host -ForegroundColor Green '5 secodns'
} else {
    write-host -ForegroundColor Red 'An invalid value was set in a variable $SecAcuracy'
}

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
    if ($SecAcuracy -eq 0) { # прибавляем по минуте к дате съемки у каждого нового файла
        $newCaptureHour=$startCaptureHour +[math]::Floor(($startCaptureMin+($numOfFiles-1))/60)
        $newCaptureHour=([String]$newCaptureHour).PadLeft(2, '0') #добавление ведущего нуля
        $newCaptureMin=$startCaptureMin+($numOfFiles-1)-[math]::Floor(($startCaptureMin+($numOfFiles-1))/60)*60
        $newCaptureMin=([String]$newCaptureMin).PadLeft(2, '0') #добавление ведущего нуля
        $commandString='-AllDates="'+$newCaptureDate+' '+$newCaptureHour+':'+$newCaptureMin+':00" '
    } elseif ($SecAcuracy -eq 1) { # прибавляем по 5 секунд к дате съемки у каждого нового файла
        $newCaptureSec=($startCaptureSec+($numOfFiles-1)*5)-[math]::Floor(($startCaptureSec+($numOfFiles-1)*5)/60)*60
        $newCaptureSec=([String]$newCaptureSec).PadLeft(2, '0') #добавление ведущего нуля

        $newCaptureMin=$startCaptureMin+[math]::Floor(($numOfFiles-1)*5/60+0.00001) # здесь 0.00001 - это костыль, чтобы правильнее работало округление
        $newCaptureMin=([String]$newCaptureMin).PadLeft(2, '0') #добавление ведущего нуля

        $newCaptureHour=$startCaptureHour+[math]::Floor(($numOfFiles-1)*5/3600+0.00001)
        $newCaptureHour=([String]$newCaptureHour).PadLeft(2, '0') #добавление ведущего нуля

        $commandString='-AllDates="'+$newCaptureDate+' '+$newCaptureHour+':'+$newCaptureMin+':'+$newCaptureSec+'" '
    }
    # доработка строки с параметрами
    if ($OverwriteOriginal -eq 0) {
        $commandString=$commandString + $FileSpec
    } else {
        $commandString=$commandString + '-overwrite_original ' + $FileSpec
    }
    write-host ' set parameter: '$commandString
    # пример    -AllDates="1998:02:01 12:01:00"' IMG_199802.01.psd  
    #------------------------------------------------------------------
    #здесь вся происходит изменение файла
    #------------------------------------------------------------------
    Start-Process -FilePath  .\exiftool.exe  -ArgumentList $commandString -Wait -NoNewWindow

    #------------------------------------------------------------------
} #конец перебора файлов
write-host $numOfFiles 'picture files found in folder'
#
