import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/stock_transaction.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Products Collection
  CollectionReference get _productsCollection => _firestore.collection('products');
  CollectionReference get _suppliersCollection => _firestore.collection('suppliers');
  CollectionReference get _stockTransactionsCollection => _firestore.collection('stock_transactions');

  // Product Operations
  Future<void> addProduct(Product product) async {
    await _productsCollection.doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _productsCollection.doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }

  Stream<List<Product>> getProducts() {
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<Product?> getProduct(String productId) async {
    final doc = await _productsCollection.doc(productId).get();
    if (doc.exists) {
      return Product.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Supplier Operations
  Future<void> addSupplier(Supplier supplier) async {
    await _suppliersCollection.doc(supplier.id).set(supplier.toMap());
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _suppliersCollection.doc(supplier.id).update(supplier.toMap());
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _suppliersCollection.doc(supplierId).delete();
  }

  Stream<List<Supplier>> getSuppliers() {
    return _suppliersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Supplier.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Stock Transaction Operations
  Future<void> addStockTransaction(StockTransaction transaction) async {
    await _stockTransactionsCollection.doc(transaction.id).set(transaction.toMap());

    // Update product stock
    final product = await getProduct(transaction.productId);
    if (product != null) {
      int newStock = product.currentStock;
      if (transaction.type == TransactionType.stockIn) {
        newStock += transaction.quantity;
      } else {
        newStock -= transaction.quantity;
      }

      final updatedProduct = product.copyWith(currentStock: newStock);
      await updateProduct(updatedProduct);
    }
  }

  Stream<List<StockTransaction>> getStockTransactions() {
    return _stockTransactionsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StockTransaction.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Dashboard Analytics
  Future<Map<String, dynamic>> getDashboardData() async {
    final productsSnapshot = await _productsCollection.get();
    final suppliersSnapshot = await _suppliersCollection.get();
    final transactionsSnapshot = await _stockTransactionsCollection
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 30)))
        .get();

    int totalProducts = productsSnapshot.docs.length;
    int totalSuppliers = suppliersSnapshot.docs.length;
    int lowStockProducts = 0;
    double totalValue = 0;

    for (var doc in productsSnapshot.docs) {
      final product = Product.fromMap(doc.data() as Map<String, dynamic>);
      if (product.currentStock <= product.minStockLevel) {
        lowStockProducts++;
      }
      totalValue += product.currentStock * product.price;
    }

    return {
      'totalProducts': totalProducts,
      'totalSuppliers': totalSuppliers,
      'lowStockProducts': lowStockProducts,
      'totalValue': totalValue,
      'recentTransactions': transactionsSnapshot.docs.length,
    };
  }
}