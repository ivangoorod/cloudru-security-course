# Security Course: стенд «Незабудка» на Cloud.ru Evolution

Адаптация сценария [YandexCloud-Security-Course-KeyCloakVersion](https://github.com/Sayanaro/YandexCloud-Security-Course-KeyCloakVersion) для облака **Cloud.ru Evolution**. Сценарий разворачивает тестовую инфраструктуру интернет-магазина «Незабудка» для курса лабораторных работ по защите информации в облаке (лабораторная № 1 «Подготовка тестовой инфраструктуры»).

История репозитория начинается с исходных коммитов автора курса. Все изменения для cloud.ru собраны в отдельный коммит сверху, поэтому их видно в `git diff` / на странице коммита.

## Что разворачивается

| ВМ | Внутренний IP | Что внутри |
|---|---|---|
| `dc01` | 10.60.1.10 | bind9 (зона `yp-lab.edu`), Root CA + Issuing CA, CRL/AIA на Apache (`crl.yp-lab.edu`), PostgreSQL, Keycloak 18 на `https://dc01.yp-lab.edu:8443` |
| `opencartshop2` | 10.60.1.20 | Apache + PHP 8.1 + MySQL + OpenCart 4.0.2.3 (установщик проходится в браузере, как в методичке) |
| `ws` | 10.60.1.30 | XFCE + TigerVNC + Google Chrome, доверяет корпоративной PKI |

Также создаются: VPC, подсеть 10.60.1.0/24, три публичных IP, группа безопасности `lab1-allow-all` и SSH-ключ `pt_key.pem`.

Имена пользователей ВМ (`ubuntu`, `sles`, `yc-user`) и команды оставлены как в методических указаниях, поэтому их шаги выполняются без изменений.

## Чем отличается от версии для Yandex Cloud

| Yandex Cloud | Cloud.ru Evolution | Почему |
|---|---|---|
| Провайдер `yandex-cloud/yandex`, OAuth-токен | Провайдер `cloudru/cloud` 2.1.5, ключ доступа сервисного аккаунта | Другое облако |
| Managed Service for PostgreSQL | PostgreSQL на `dc01` | Проще и дешевле для учебного стенда |
| ВМ магазина из образа OpenCart в Marketplace | Ubuntu 22.04, LAMP и OpenCart ставит cloud-init | В cloud.ru нет такого образа |
| `ws` на openSUSE + KDE | `ws` на Ubuntu 22.04 + XFCE | В каталоге образов cloud.ru нет openSUSE |
| Три подсети в трёх зонах | Одна подсеть в `ru.AZ-1` | Исходный сценарий использовал только первую |
| Без групп безопасности, всё открыто | Группа `lab1-allow-all`, тоже всё открыто | В cloud.ru сетевой интерфейс не создаётся без группы. Порты закрываются во 2-й лабораторной |
| DNS-форвардер — адрес `x.x.x.2` подсети | systemd-resolved: `yp-lab.edu` → dc01, остальное → 8.8.8.8 | Другая сетевая модель |
| Конфиги OpenSSL скачиваются с GitHub при установке | Вшиты в cloud-init | Меньше внешних зависимостей |
| 2 vCPU (100%), 4 ГБ | `lowcost10-2-4`: 2 vCPU (10%), 4 ГБ | Экономия гранта. Меняется в `variables.tf` |

Скрипты установки также дорабатывались:

- **Ожидание apt.** Скрипты ждут, пока cloud-init отпустит блокировку apt, и останавливаются, если пакеты не установились.
- **Секреты.** Пароль БД Keycloak хранится в `keycloak.conf` с правами 600, а не в systemd-юните. Файл с паролями после установки удаляется.
- **Сертификат Keycloak.** Выдаётся с SAN `dc01.yp-lab.edu` и `keycloak.yp-lab.edu` и полной цепочкой.
- **VNC.** TigerVNC слушает не только localhost. Добавлено правило polkit, чтобы в VNC-сессии не всплывал запрос пароля root от colord.

## Подготовка (один раз)

1. **Аккаунт.** Зарегистрируйтесь в [Cloud.ru Evolution](https://cloud.ru/evolution). Физлицо при привязке карты получает грант 4 000 бонусов, этого с запасом хватает на курс.
2. **Сервисный аккаунт.** Консоль → «Пользователи» → «Сервисные аккаунты» → «Создать аккаунт», уровень «Проект». Дайте **только** роли `eiv.admin` (Evolution Compute) и `vpc.admin` (Evolution VPC): это принцип минимальных привилегий.
3. **Ключ доступа.** В карточке аккаунта откройте «Ключи доступа» → «Создать». Скопируйте Key ID и Secret: секрет показывается один раз.
4. **Переменные окружения.** Заполните `cloudru.env.example` и сохраните как `~/.cloudru.env` (права 600). В репозиторий его не коммитьте.
5. **Terraform.** Нужен Terraform ≥ 1.5.
6. **Провайдер cloud.ru.** Его нет в registry.terraform.io, поэтому бинарник нужно положить вручную. Скачайте файл под свою ОС из [релизов cloud-ru/evo-terraform](https://github.com/cloud-ru/evo-terraform/releases/tag/v2.1.5):

   | ОС | Файл релиза | Куда положить (имя файла — `terraform-provider-cloud_v2.1.5`) |
   |---|---|---|
   | macOS Apple Silicon | `..._darwin_arm64` | `~/.terraform.d/plugins/cloud.ru/cloudru/cloud/2.1.5/darwin_arm64/` |
   | macOS Intel | `..._darwin_amd64` | `~/.terraform.d/plugins/cloud.ru/cloudru/cloud/2.1.5/darwin_amd64/` |
   | Linux | `..._linux_amd64` | `~/.terraform.d/plugins/cloud.ru/cloudru/cloud/2.1.5/linux_amd64/` |
   | Windows | `..._windows_amd64` | `%APPDATA%\terraform.d\plugins\cloud.ru\cloudru\cloud\2.1.5\windows_amd64\` (с расширением `.exe`) |

   На macOS и Linux:
   ```bash
   V=2.1.5; OS=darwin_arm64   # подставьте свою платформу
   D=~/.terraform.d/plugins/cloud.ru/cloudru/cloud/$V/$OS
   mkdir -p $D && curl -L -o $D/terraform-provider-cloud_v$V \
     https://github.com/cloud-ru/evo-terraform/releases/download/v$V/terraform-provider-cloud_${V}_$OS
   chmod +x $D/terraform-provider-cloud_v$V
   ```

## Запуск

```bash
source ~/.cloudru.env
terraform init
terraform plan      # 21 ресурс к созданию
terraform apply     # спросит пароли Keycloak и PostgreSQL
terraform output instructions
```

Пароли: не короче 8 символов, со строчными и заглавными буквами, цифрой и спецсимволом из `@#%&*/:;,.?+=-_`. Кавычки, `$`, `\` и пробел не допускаются.

После `apply` установка внутри ВМ идёт ещё 10–20 минут. Ход установки пишется в `/var/log/lab-prep.log`, а в конце появляется строка `LAB PREP DONE`.

Дальше всё как в методичке:

- **OpenCart.** Откройте `http://<IP opencartshop2>/` и пройдите установщик. Реквизиты БД выводит команда из `terraform output instructions`. После установки удалите каталог `install`: `sudo rm -rf /var/www/html/install`.
- **VNC.** Подключитесь `ssh -i pt_key.pem sles@<IP ws>` и выполните `vncserver -geometry 1200x800 -depth 32 -name remote-desktop :1`. Затем откройте VNC-клиентом `<IP ws>:5901`.
- **Проверка PKI.** В Chrome на `ws` откройте `https://dc01.yp-lab.edu:8443`. Сертификат должен быть от «LAB Issuing CA» и без предупреждений.

## Стоимость и экономия гранта

- Работающая ВМ `lowcost10-2-4` вместе с диском обходится примерно в 3 ₽ в час.
- Выключенный стенд стоит около 40 ₽ в сутки: диски и публичные IP оплачиваются и у остановленных ВМ.
- Между занятиями можно выключить ВМ в консоли. Тогда всё сохранится, а после включения на `ws` нужно снова запустить `vncserver`.
- Можно и удалить стенд командой `terraform destroy`. Это дешевле, но после нового `apply` установщик OpenCart придётся пройти заново.

## Известные проблемы cloud.ru и их обход

| Симптом | Причина | Что сделано / что делать |
|---|---|---|
| `Provider produced inconsistent result ... dns_servers` | Баг провайдера 2.1.5: API возвращает список DNS в другом порядке | В подсети оставлен один DNS, внутренний задаётся на ВМ |
| `Interface is not found` при пересоздании ВМ | cloud.ru удаляет сетевые интерфейсы вместе с ВМ | Пересоздавайте ВМ вместе с интерфейсом: `terraform apply -replace='cloudru_evolution_compute_vm.vm["dc01"]' -replace='cloudru_evolution_compute_interface.nic["dc01"]'` |
| ВМ не отвечает, в серийной консоли `(initramfs)` | Разовый сбой подготовки диска | Пересоздайте диск, ВМ и интерфейс через `-replace` |
| В консоли Shared/Balanced «временно недоступны» | Ограничения веб-консоли | Через API/Terraform `lowcost10-2-4` и `low-2-4` создаются. Запасной вариант — `gen-2-4` |
| `terraform init` не видит провайдер cloud.ru | Его нет в публичном реестре | См. шаг 6 подготовки |
| Ошибки 403 от `*.api.cloud.ru` или `registry.terraform.io` | Корпоративный прокси (`HTTPS_PROXY`) | `export NO_PROXY="$NO_PROXY,.cloud.ru"` или запуск вне корпоративной сети |

## Безопасность

- `terraform.tfstate` содержит пароли Keycloak и PostgreSQL: они передаются на ВМ через cloud-init. Файлы `*.tfstate` и `pt_key.pem` перечислены в `.gitignore`, не коммитьте их.
- Стенд **намеренно небезопасен**: группа `lab1-allow-all` открывает все порты, а VNC и Keycloak доступны из интернета. Это исходное состояние курса. Закрытие портов, VPN, федерация удостоверений и SIEM — предмет следующих лабораторных.

## Лицензия

Исходный сценарий © Sayanaro и участники, [GPL-2.0](LICENSE). Адаптация для cloud.ru распространяется на тех же условиях.
