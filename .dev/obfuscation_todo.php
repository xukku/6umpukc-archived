<?php

// конвертация namespace - нужно для полной обфускации

// установить парсер php
//		cd ~/bin/; mkdir php-parser; cd php-parser; composer require nikic/php-parser

use PhpParser\ParserFactory;
use PhpParser\PrettyPrinter;
use PhpParser\NodeTraverser;
use PhpParser\NodeVisitor\NameResolver;
use PhpParser\Node;
use PhpParser\Node\Stmt;

if (file_exists(__DIR__ . '/php-parser/vendor/autoload.php')) {

	require __DIR__ . '/php-parser/vendor/autoload.php';

	class NamespaceConverter extends \PhpParser\NodeVisitorAbstract
	{
		public function leaveNode(Node $node) {
			if ($node instanceof Node\Name) {
				return new Node\Name(str_replace('\\', '_', $node->toString()));
			} elseif ($node instanceof Stmt\Class_
					  || $node instanceof Stmt\Interface_
					  || $node instanceof Stmt\Function_) {
				$node->name = str_replace('\\', '_', $node->namespacedName->toString());
			} elseif ($node instanceof Stmt\Const_) {
				foreach ($node->consts as $const) {
					$const->name = str_replace('\\', '_', $const->namespacedName->toString());
				}
			} elseif ($node instanceof Stmt\Namespace_) {
				// returning an array merges is into the parent array
				return $node->stmts;
			} elseif ($node instanceof Stmt\Use_) {
				// remove use nodes altogether
				return NodeTraverser::REMOVE_NODE;
			}
		}
	}

	function FilterConvertNamespaces($content) {
		$parser        = (new ParserFactory())->create(ParserFactory::PREFER_PHP7);
		$traverser     = new NodeTraverser();
		$prettyPrinter = new PrettyPrinter\Standard();

		$traverser->addVisitor(new NameResolver()); // we will need resolved names
		$traverser->addVisitor(new NamespaceConverter()); // our own node visitor

		try {
			$stmts = $parser->parse($content);
			$stmts = $traverser->traverse($stmts);
			$content = $prettyPrinter->prettyPrintFile($stmts);
			return $content;
		} catch (PhpParser\Error $e) {
			echo 'Parse Error: ' . $e->getMessage() . "\n";
		}
		return $content;
	}
}
