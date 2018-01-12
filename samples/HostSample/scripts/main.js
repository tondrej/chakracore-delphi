import('json2').then(
	m => {
		var f = function (console) {
			console.log("Current time: ", new Date());
			console.info("%s: %s", "Info", "Info message");
			console.warn("%s: %s", "Warning", "Warning message");
			console.error("%s: %s %d", "Error", "Error message", 42);

			var o = {int_prop: 42, str_prop: "Hello", float_prop: 3.14, array_prop: [42, "Hello", 3.14]};
			console.log(JSON.stringify(o));
			console.log("%o", o);
		};

		f(console);
		console.log("");

		var console2 = new TConsole();
		f(console2);
	}
).catch(
	e => {
		console.error("%o", e);
	}
);
