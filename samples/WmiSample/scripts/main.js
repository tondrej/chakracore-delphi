function wmiInstancesOf(service, className) {
  console.log(`***** InstancesOf('${className}') *****`);
  let items = service.InstancesOf(className);
  items.forEach((item, i) => {
    if (i > 0) {
      console.log('');
    }
    item.Properties_.forEach((p) => {
      console.log(`${p.Name}: ${item[p.Name]}`);
    });
  });
}

function wmiExecQuery(service, query) {
  console.log(`***** ExecQuery('${query}') *****`);
  let items = service.ExecQuery(query);
  items.forEach((item, i) => {
    if (i == 0) {
      console.log(item.Properties_.map((p) => p.Name).join(', '));
    }
    console.log(item.Properties_.map((p) => item[p.Name]).join(', '));
  });
}

const computerName = '.';
const namespace = '';
const userName = '';
const password = '';

let locator = createOleObject('WbemScripting.SWbemLocator');
let service = locator.ConnectServer(computerName, namespace, userName, password);

wmiInstancesOf(service, 'Win32_OperatingSystem');
console.log('');

wmiExecQuery(service, 'select Name, Status from Win32_Service');
console.log('');

wmiExecQuery(service, 'select * from Win32_Process');
console.log('');

