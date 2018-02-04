var p = new Promise((resolve, reject) => {
	setTimeout(c => {
		resolve("Success!");
	}, 100, console);
});
p.then(
  r => { console.info("Promise: %o", r); }
).catch(
	e => { console.error("Promise: %o", e); }
);

testPromise(200).then(
  x => {
	console.info("testPromise: %o", x);
}).catch(
  e => {
	  console.error("testPromise: %o", e);
  }
);

import('json2').then(
	m => {
		setTimeout(c => { c.log("(timeout 1000) Current time: ", new Date()) }, 1000, console);
		setTimeout(c => { c.log("(timeout 2000) Current time: ", new Date()) }, 2000, console);
		setTimeout(c => {
			c.log("(timeout 3000) Current time: ", new Date());
			setInterval(c => { c.log("(interval 500) Current time: ", new Date()) }, 500, console);
		}, 3000, console);

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

		var console2 = new Console();
		f(console2);
	}
).catch(
	e => {
		console.error("%o", e);
	}
);
