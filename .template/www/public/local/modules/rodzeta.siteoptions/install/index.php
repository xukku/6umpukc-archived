<?php

if (!defined('B_PROLOG_INCLUDED') || B_PROLOG_INCLUDED !== true) {
	die();
}

use Bitrix\Main\Localization\Loc;

Loc::loadMessages(__FILE__);

class rodzeta_siteoptions extends CModule
{
	public $MODULE_ID = 'rodzeta.siteoptions';

	public $MODULE_VERSION;
	public $MODULE_VERSION_DATE;
	public $MODULE_NAME;
	public $MODULE_DESCRIPTION;
	public $MODULE_GROUP_RIGHTS;
	public $PARTNER_NAME;
	public $PARTNER_URI;

	public function __construct()
	{
		$this->MODULE_ID = 'rodzeta.siteoptions';

		$arModuleVersion = [];
		include __DIR__.'/version.php';

		if (!empty($arModuleVersion['VERSION']))
		{
			$this->MODULE_VERSION = $arModuleVersion['VERSION'];
			$this->MODULE_VERSION_DATE = $arModuleVersion['VERSION_DATE'];
		}

		$this->MODULE_NAME = Loc::getMessage('RODZETA_SITEOPTIONS_MODULE_NAME');
		$this->MODULE_DESCRIPTION = Loc::getMessage('RODZETA_SITEOPTIONS_MODULE_DESCRIPTION');
		$this->MODULE_GROUP_RIGHTS = 'N';

		$this->PARTNER_NAME = 'Rodzeta';
		$this->PARTNER_URI = 'http://rodzeta.ru/';
	}

	public function InstallFiles()
	{
		return true;
	}

	public function UninstallFiles()
	{
		return true;
	}

	public function InstallDB()
	{
		RegisterModule($this->MODULE_ID);
		RegisterModuleDependences('main', 'OnPageStart', $this->MODULE_ID);
	}

	public function UnInstallDB()
	{
		UnRegisterModuleDependences('main', 'OnPageStart', $this->MODULE_ID);
		UnregisterModule($this->MODULE_ID);
	}

	public function DoInstall()
	{
		global $APPLICATION;
		if (version_compare(PHP_VERSION, '7.4', '<'))
		{
			$APPLICATION->ThrowException(Loc::getMessage('RODZETA_SITEOPTIONS_REQUIREMENTS_PHP_VERSION'));

			return false;
		}
		$this->InstallDB();
		$this->InstallFiles();

		return true;
	}

	public function DoUninstall()
	{
		$this->UnInstallDB();
		$this->UninstallFiles();

		return true;
	}
}
