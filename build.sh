
rm -R tmp
mkdir tmp
cd tmp

curl -OL http://www.1c-bitrix.ru/download/first_site_encode_php5.tar.gz

tar -xvzf first_site_encode_php5.tar.gz \
    --exclude "./bitrix/modules/iblock"
rm first_site_encode_php5.tar.gz

tar -zcvf ../bitrix.tar.gz ./

cd ..

#    --exclude "./bitrix/modules/fileman" \
#    --exclude "./bitrix/wizards/bitrix/first_site" \
