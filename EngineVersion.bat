:: Указываем путь к git.exe
set "PATH=c:\Program Files (x86)\Git\bin\"
:: Скачиваем репозиторий
git clone https://github.com/Urho3D/Urho3D.git
:: Переходим в папку со скачанными исходниками
cd Urho3D
:: Возвращаем состояние репозитория к определённой версии (18 мая 2016)
git reset --hard 250bfbaafe39dfca68acd2f6146f5344415a5318
:: Ждём нажатия ENTER для закрытия консоли
pause
