
rm -R tmp
mkdir tmp
cd tmp

curl -OL http://www.1c-bitrix.ru/download/first_site_encode_php5.tar.gz

# small
tar -xvzf first_site_encode_php5.tar.gz \
    --exclude "./bitrix/modules/iblock"
rm first_site_encode_php5.tar.gz
tar -zcvf ../small.tar.gz ./

# minimal
rm -R ./bitrix/modules/fileman
rm -R ./bitrix/wizards/bitrix/first_site
tar -zcvf ../minimal.tar.gz ./

cd ..
