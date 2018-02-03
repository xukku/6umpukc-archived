<?php

// extended dbconn.php init

namespace
{
	use Bitrix\Main\DI\ServiceLocator;
	use Bitrix\Main\Mail;

	new class()
	{
		private $settings;

		public function __construct()
		{
			$this->initSettings();
			$this->initEncoding();
			$this->initDbConnectionVars();
			$this->initCustomMailer();
			$this->initCron();
		}

		private function initSettings()
		{
			$this->settings = require dirname(__DIR__) . '/.settings.php';
			//TODO!!! добавить из .settings_extra.php
		}

		private function initEncoding()
		{
			if (!empty($this->settings['utf_mode']['value']))
			{
				define('BX_UTF', true);
			}
			else
			{
				mb_internal_encoding('Windows-1251');
				setlocale(LC_ALL, 'ru_RU.CP1251');
				setlocale(LC_NUMERIC,'C');
			}
		}

		private function initDbConnectionVars()
		{
			global $DBType, $DBHost, $DBLogin, $DBPassword, $DBName;

			if (!empty($this->setting['connections']['value']['default']))
			{
				//$DBType = 'mysql';
				$DBHost = $this->setting['connections']['value']['default']['host'];
				$DBLogin = $this->setting['connections']['value']['default']['login'];
				$DBPassword = $this->setting['connections']['value']['default']['password'];
				$DBName = $this->setting['connections']['value']['default']['database'];
			}
		}

		private function initCustomMailer()
		{
			if (function_exists('custom_mail'))
			{
				return;
			}

		    function custom_mail(
			    	$to,
			    	$subject,
			    	$message,
			    	$additional_headers = '',
			    	$additional_parameters = '',
			    	Mail\Context $context = null
			    )
		    {
				$serviceLocator = ServiceLocator::getInstance();
				if ($serviceLocator->has('siteoptions.mailer'))
				{
					$mailer = $serviceLocator->get('siteoptions.mailer');
					return $mailer->send(
						$to,
						$subject,
						$message,
						$additional_headers,
						$additional_parameters,
						$context
					);
				}

				return true;
		    }
		}

		private function initCron()
		{
			//TODO!!! init cron params
		    // https://dev.1c-bitrix.ru/learning/course/?COURSE_ID=43&LESSON_ID=2943
		    // * * * * * /usr/bin/php -f /PATH-TO-SITE/bitrix/modules/main/tools/cron_events.php

		    // или скопировать функционал https://marketplace.1c-bitrix.ru/solutions/askaron.agents/
		}
	};
}
