
import 'package:flutter/material.dart';

void main() {
  runApp(const MufinBillingApp());
}

const Color navy = Color(0xFF173D70);
const Color blue = Color(0xFF247BFA);
const Color green = Color(0xFF13A568);
const Color background = Color(0xFFF3F7FC);

class Product {
  String name;
  double mrp;
  double rate;
  int stock;
  int qty;

  Product(this.name, this.mrp, this.rate, this.stock,
      {this.qty = 0});
}

class BillRecord {
  final String customer;
  final double amount;
  final DateTime date;
  final int items;

  BillRecord(this.customer, this.amount, this.date, this.items);
}

class MufinBillingApp extends StatelessWidget {
  const MufinBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mufin Billing Software',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        fontFamily: 'Arial',
      ),
      home: const BillingDashboard(),
    );
  }
}

class BillingDashboard extends StatefulWidget {
  const BillingDashboard({super.key});

  @override
  State<BillingDashboard> createState() => _BillingDashboardState();
}

class _BillingDashboardState extends State<BillingDashboard> {
  int selectedPage = 0;
  double discount = 5;

  final customerController =
      TextEditingController(text: 'Rahul Kumar');
  final phoneController =
      TextEditingController(text: '9876543210');
  final searchController = TextEditingController();

  final List<Product> products = [
    Product('Notebook', 60, 45, 50, qty: 2),
    Product('Pen', 15, 10, 100, qty: 5),
    Product('File', 35, 25, 32, qty: 3),
    Product('Pencil', 12, 8, 60, qty: 4),
    Product('Eraser', 10, 6, 75, qty: 2),
  ];

  final List<BillRecord> history = [];

  double get subtotal =>
      products.fold(0, (sum, p) => sum + p.rate * p.qty);

  int get totalItems =>
      products.fold(0, (sum, p) => sum + p.qty);

  double get discountAmount => subtotal * discount / 100;

  double get gstAmount => (subtotal - discountAmount) * 0.05;

  double get netAmount =>
      subtotal - discountAmount + gstAmount;

  String money(double value) => '₹${value.toStringAsFixed(2)}';

  String get billNumber =>
      'INV-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void dispose() {
    customerController.dispose();
    phoneController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void saveBill() {
    if (totalItems == 0) {
      notify('Add at least one product to the bill.');
      return;
    }

    for (final p in products) {
      if (p.qty > p.stock) {
        notify('Insufficient stock for ${p.name}.');
        return;
      }
    }

    setState(() {
      history.insert(
        0,
        BillRecord(
          customerController.text.trim().isEmpty
              ? 'Walk-in Customer'
              : customerController.text.trim(),
          netAmount,
          DateTime.now(),
          totalItems,
        ),
      );

      for (final p in products) {
        p.stock -= p.qty;
        p.qty = 0;
      }

      discount = 5;
    });

    notify('Bill saved successfully!');
  }

  void clearBill() {
    setState(() {
      for (final p in products) {
        p.qty = 0;
      }
      discount = 5;
      customerController.clear();
      phoneController.clear();
    });
    notify('Current bill cleared.');
  }

  void addProductDialog() {
    final name = TextEditingController();
    final mrp = TextEditingController();
    final rate = TextEditingController();
    final stock = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration:
                    const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: mrp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'MRP'),
              ),
              TextField(
                controller: rate,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Sales Rate'),
              ),
              TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final productName = name.text.trim();
              final productMrp = double.tryParse(mrp.text);
              final productRate = double.tryParse(rate.text);
              final productStock = int.tryParse(stock.text);

              if (productName.isEmpty ||
                  productMrp == null ||
                  productRate == null ||
                  productStock == null ||
                  productMrp < 0 ||
                  productRate < 0 ||
                  productStock < 0) {
                notify('Enter valid product details.');
                return;
              }

              setState(() {
                products.add(Product(
                  productName,
                  productMrp,
                  productRate,
                  productStock,
                ));
              });

              Navigator.pop(dialogContext);
              name.dispose();
              mrp.dispose();
              rate.dispose();
              stock.dispose();

              notify('Product added successfully.');
            },
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 850;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.inventory_2_outlined),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'MUFIN | BUSINESS BILLING SOFTWARE',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
          drawer: desktop ? null : Drawer(child: sidebar()),
          body: Row(
            children: [
              if (desktop) SizedBox(width: 205, child: sidebar()),
              Expanded(
                child: selectedPage == 0
                    ? dashboard(constraints.maxWidth)
                    : otherPage(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget sidebar() {
    final labels = [
      'Sales',
      'Inventory',
      'Current Bill',
      'History',
      'Reports',
    ];

    final icons = [
      Icons.shopping_cart_outlined,
      Icons.inventory_2_outlined,
      Icons.receipt_long,
      Icons.history,
      Icons.bar_chart,
    ];

    return Container(
      color: navy,
      child: Column(
        children: [
          const SizedBox(height: 15),
          for (int i = 0; i < labels.length; i++)
            ListTile(
              selected: selectedPage == i,
              selectedTileColor: blue,
              leading: Icon(icons[i], color: Colors.white),
              title: Text(
                labels[i],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                setState(() => selectedPage = i);
                Navigator.maybePop(context);
              },
            ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'MUFIN BILLING v1.0',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget dashboard(double width) {
    final filtered = products.where((p) {
      return p.name.toLowerCase().contains(
            searchController.text.toLowerCase(),
          );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: width > 650 ? 300 : width - 65,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search product...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: customerController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: addProductDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                ),
                onPressed: saveBill,
                icon: const Icon(Icons.save),
                label: const Text('Save Bill'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          productTable(filtered),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, box) {
              final stacked = box.maxWidth < 1000;

              final bill = currentBillCard();
              final summary = summaryCard();
              final inventory = inventoryCard();

              if (stacked) {
                return Column(
                  children: [
                    bill,
                    const SizedBox(height: 14),
                    summary,
                    const SizedBox(height: 14),
                    inventory,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: bill),
                  const SizedBox(width: 12),
                  Expanded(child: summary),
                  const SizedBox(width: 12),
                  Expanded(child: inventory),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget productTable(List<Product> list) {
    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(const Color(0xFFEAF0F8)),
          columns: const [
            DataColumn(label: Text('NO')),
            DataColumn(label: Text('PRODUCT NAME')),
            DataColumn(label: Text('QTY')),
            DataColumn(label: Text('MRP')),
            DataColumn(label: Text('RATE')),
            DataColumn(label: Text('STOCK')),
            DataColumn(label: Text('AMOUNT')),
            DataColumn(label: Text('ACTION')),
          ],
          rows: [
            for (int i = 0; i < list.length; i++)
              DataRow(
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(
                    SizedBox(
                      width: 115,
                      child: Text(
                        list[i].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 75,
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: list[i].qty,
                        items: List.generate(
                          21,
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text('$n'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => list[i].qty = value);
                        },
                      ),
                    ),
                  ),
                  DataCell(Text(money(list[i].mrp))),
                  DataCell(Text(money(list[i].rate))),
                  DataCell(
                    Text(
                      '${list[i].stock}',
                      style: TextStyle(
                        color: list[i].stock < 10
                            ? Colors.red
                            : green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(money(list[i].rate * list[i].qty)),
                  ),
                  DataCell(
                    IconButton(
                      tooltip: 'Remove product',
                      onPressed: () {
                        setState(() => products.remove(list[i]));
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget panel(String title, IconData icon, Widget child) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: const BorderSide(color: Color(0xFFD8E3F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: navy),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            child,
          ],
        ),
      ),
    );
  }

  Widget amountRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            money(value),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget currentBillCard() {
    return panel(
      'Current Bill',
      Icons.receipt_long,
      Column(
        children: [
          amountRow('Total Items', totalItems.toDouble()),
          amountRow('Sub Total', subtotal),
          Row(
            children: [
              const Expanded(child: Text('Discount (%)')),
              SizedBox(
                width: 80,
                child: DropdownButton<double>(
                  isExpanded: true,
                  value: discount,
                  items: [0, 5, 10, 15, 20].map((v) {
                    return DropdownMenuItem<double>(
                      value: v.toDouble(),
                      child: Text('$v%'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => discount = v);
                  },
                ),
              ),
            ],
          ),
          amountRow('Discount Amount', -discountAmount),
          amountRow('GST (5%)', gstAmount),
          const Divider(height: 25),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Net Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                money(netAmount),
                style: const TextStyle(
                  color: blue,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: clearBill,
                icon: const Icon(Icons.refresh),
                label: const Text('Clear'),
              ),
              FilledButton.icon(
                onPressed: saveBill,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                ),
                onPressed: showInvoice,
                icon: const Icon(Icons.print),
                label: const Text('Invoice'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget summaryCard() {
    return panel(
      'Bill Summary',
      Icons.description_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bill No: $billNumber'),
          const SizedBox(height: 8),
          Text('Customer: ${customerController.text}'),
          const SizedBox(height: 8),
          Text('Phone: ${phoneController.text}'),
          const Divider(height: 25),
          for (final p in products.where((p) => p.qty > 0))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(child: Text(p.name)),
                  Text('${p.qty} × ${money(p.rate)}'),
                  const SizedBox(width: 8),
                  Text(money(p.qty * p.rate)),
                ],
              ),
            ),
          const Divider(height: 25),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Amount',
                  style: TextStyle(
                    color: blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                money(netAmount),
                style: const TextStyle(
                  color: blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget inventoryCard() {
    final lowStock = products.where((p) => p.stock < 35).toList();

    return panel(
      'Product Inventory',
      Icons.inventory_2_outlined,
      Column(
        children: [
          for (final p in products)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(p.name),
                  ),
                  Expanded(
                    child: Text(money(p.rate)),
                  ),
                  Expanded(
                    child: Text(
                      '${p.stock}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: p.stock < 10 ? Colors.red : green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠ Low Stock Alert',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (lowStock.isEmpty)
                  const Text('No low stock products.')
                else
                  for (final p in lowStock)
                    Text('${p.name} — ${p.stock} items left'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget otherPage() {
    if (selectedPage == 1) return inventoryPage();
    if (selectedPage == 2) return dashboard(1000);
    if (selectedPage == 3) return historyPage();
    return reportsPage();
  }

  Widget inventoryPage() {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Product Inventory'),
        backgroundColor: background,
        actions: [
          IconButton(
            onPressed: addProductDialog,
            icon: const Icon(Icons.add_box, color: blue),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: products.map((p) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2, color: navy),
              title: Text(p.name),
              subtitle: Text(
                'MRP: ${money(p.mrp)} | Rate: ${money(p.rate)}',
              ),
              trailing: Text(
                'Stock: ${p.stock}',
                style: TextStyle(
                  color: p.stock < 10 ? Colors.red : green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget historyPage() {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Bill History'),
        backgroundColor: background,
      ),
      body: history.isEmpty
          ? const Center(child: Text('No saved bills yet.'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final b = history[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.receipt_long,
                      color: blue,
                    ),
                    title: Text(b.customer),
                    subtitle: Text(
                      '${b.date.day}-${b.date.month}-${b.date.year}'
                      ' | Items: ${b.items}',
                    ),
                    trailing: Text(
                      money(b.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget reportsPage() {
    final sales = history.fold<double>(
      0,
      (sum, bill) => sum + bill.amount,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Sales Reports'),
        backgroundColor: background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          reportCard('Total Bills', '${history.length}', Icons.receipt),
          reportCard('Total Sales', money(sales), Icons.currency_rupee),
          reportCard(
            'Products',
            '${products.length}',
            Icons.inventory_2,
          ),
          reportCard(
            'Available Stock',
            '${products.fold<int>(0, (sum, p) => sum + p.stock)}',
            Icons.warehouse,
          ),
        ],
      ),
    );
  }

  Widget reportCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: blue, size: 30),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: navy,
          ),
        ),
      ),
    );
  }

  void showInvoice() {
    if (totalItems == 0) {
      notify('Add products before viewing the invoice.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MUFIN - INVOICE'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice: $billNumber'),
                const SizedBox(height: 8),
                Text('Customer: ${customerController.text}'),
                Text('Phone: ${phoneController.text}'),
                const Divider(height: 25),
                for (final p in products.where((p) => p.qty > 0))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(p.name)),
                        Text('${p.qty} × ${money(p.rate)}'),
                      ],
                    ),
                  ),
                const Divider(height: 25),
                amountRow('Subtotal', subtotal),
                amountRow('Discount', -discountAmount),
                amountRow('GST (5%)', gstAmount),
                const Divider(),
                amountRow('NET AMOUNT', netAmount),
                const SizedBox(height: 12),
                const Text('Thank you for your purchase!'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              saveBill();
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Bill'),
          ),
        ],
      ),
    );
  }
}
