
rm -R tmp
mkdir tmp
cd tmp

curl -OL http://www.1c-bitrix.ru/download/first_site_encode_php5.tar.gz
tar -xvzf first_site_encode_php5.tar.gz ./
rm -R bitrix/modules/fileman
rm -R bitrix/modules/iblock
rm first_site_encode_php5.tar.gz
