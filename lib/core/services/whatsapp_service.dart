import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:aconita_mart_pos/data/models/order.dart';

class WhatsAppService {
  WhatsAppService._();
  static final WhatsAppService instance = WhatsAppService._();

  Future<bool> sendReceipt(Order order, String phone) async {
    final curr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final date = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate);

    final buffer = StringBuffer();
    buffer.writeln('*STRUK TRANSAKSI ACONITA MART*');
    buffer.writeln('--------------------------------');
    buffer.writeln('No. Struk: ${order.orderNo}');
    buffer.writeln('Tanggal  : $date');
    if (order.memberName != null) {
      buffer.writeln('Anggota  : ${order.memberName}');
    }
    buffer.writeln('--------------------------------');
    for (final item in order.items) {
      buffer.writeln('${item.productName} x${item.quantity}');
      buffer.writeln('  ${curr.format(item.subtotal)}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('*Total    : ${curr.format(order.finalAmount)}*');
    buffer.writeln('Bayar    : ${curr.format(order.paidAmount)}');
    buffer.writeln('Kembali  : ${curr.format(order.changeAmount)}');
    buffer.writeln('Metode   : ${order.paymentMethod.toUpperCase()}');
    buffer.writeln('--------------------------------');
    buffer.writeln('Terima kasih telah berbelanja di Koperasi Aconita Mart!');

    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final targetPhone = cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;

    final url = Uri.parse('https://wa.me/$targetPhone?text=${Uri.encodeComponent(buffer.toString())}');
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
