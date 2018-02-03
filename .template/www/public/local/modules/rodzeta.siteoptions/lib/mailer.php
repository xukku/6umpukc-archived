<?php

namespace Rodzeta\Siteoptions;

use Bitrix\Main\Mail;

if (!defined('B_PROLOG_INCLUDED') || B_PROLOG_INCLUDED !== true) die();

class Mailer
{
	protected function getLogPath()
	{
		return $_SERVER['DOCUMENT_ROOT']
			. '/bitrix/modules/.' . SITE_ID . '.mail.log';
	}

    public function send(
	    	$to,
	    	$subject,
	    	$message,
	    	$additional_headers = '',
	    	$additional_parameters = '',
	    	Mail\Context $context = null
	    )
    {
    	// TODO!!! сохранять в файл в формате почтового клиента
    	$path = $this->getLogPath();
        file_put_contents(
            $path,
            print_r([
                'TO' => $to,
                'SUBJECT' => $subject,
                'BODY' => $message,
                'HEADERS' => $additional_headers,
                'PARAMS' => $additional_parameters
            ], true)
            . "\n========\n",
            FILE_APPEND
        );

        return true;
    }
}
