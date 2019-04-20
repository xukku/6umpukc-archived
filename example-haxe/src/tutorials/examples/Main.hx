
// declare(strict_types=1);

package tutorials.examples;

import bitrix.main.Application;

class Person
{
	public /*string*/ var Name = '';

	public function new( name: String = '')
	{
		this.Name = name;
	}

	public static function multiply( x: Application,  y: Float = 2): Int
	{
		return Std.int(x * y);
	}

	public function fun(): Int
	{
		var test = [1, 2, 3, 4, 5];
		var result = 0;
		for    (v in test) {
			result += v;
			if (v > 0) {
				v = -1;
			} else {
				v = -1;
			}
			trace(result, v);
		}
		return result + 2100;
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
	public override function fun(): Int
	{
		return super.fun() + 5;
	}
}

class Main
{
	public static function main()
	{
		trace(Person.multiply(16, 1.4));
		trace(new Test('111')); // var_dump((string)new Test('111'))
		trace((new Test('111')).fun());
		trace((new Person('111')).fun());
	}
}

// Main::main();
