<?php

declare(strict_types=1);

namespace tutorials\examples;

use bitrix\main\Application;

class Person
{
	public /*string*/ $Name = '';

	public function __construct(string $name = '')
	{
		$this->Name = $name;
	}

	public static function multiply(Application $x, float $y = 2): int
	{
		return intval($x * $y);
	}

	public function fun(): int
	{
		/*var*/ $test = [1, 2, 3, 4, 5];
		/*var*/ $result = 0;
		foreach ($test as $v) {
			$result += $v;
			if ($v > 0) {
				$v = -1;
			} else {
				$v = -1;
			}
			trace($result, $v);
		}
		return $result + 2100;
	}

	/*
	public function __toString():string
	{
		return '[' . $this->Name . ']';
	}
	*/
}

class Test extends Person
{
	public /*override*/ function fun(): int
	{
		return parent::fun() + 5;
	}
}

class Main
{
	public static function main()
	{
		var_dump(Person::multiply(16, 1.4));
		var_dump(new Test('111')); // var_dump((string)new Test('111'))
		var_dump((new Test('111'))->fun());
		var_dump((new Person('111'))->fun());
	}
}

// Main::main();
