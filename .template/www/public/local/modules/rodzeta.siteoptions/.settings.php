<?php

namespace Rodzeta\Siteoptions;

return [
	'services' => [
		'value' => [
			'siteoptions.mailer' => [
				'className' => Mailer::class,
			],
		],
		'readonly' => false,
	],
];