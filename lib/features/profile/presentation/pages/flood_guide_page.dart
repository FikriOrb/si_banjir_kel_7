import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';

class FloodGuidePage extends StatelessWidget {
  const FloodGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panduan Siaga Banjir'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(
                icon: Icon(LucideIcons.calendar, size: 20),
                text: 'Sebelum Banjir',
              ),
              Tab(
                icon: Icon(LucideIcons.alertTriangle, size: 20),
                text: 'Saat Banjir',
              ),
              Tab(
                icon: Icon(LucideIcons.heartPulse, size: 20),
                text: 'Setelah Banjir',
              ),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: TabBarView(
              children: [
                _buildBeforeTab(context),
                _buildDuringTab(context),
                _buildAfterTab(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBeforeTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeroBanner(
          title: 'Pra-Bencana (Persiapan)',
          desc: 'Tindakan pencegahan dan persiapan sebelum banjir melanda untuk meminimalkan risiko korban dan kerugian harta benda.',
          color: Colors.amber.shade700,
          icon: LucideIcons.calendarClock,
        ),
        const SizedBox(height: 20),
        _buildGuideCard(
          title: '1. Pemantauan & Edukasi',
          icon: LucideIcons.radio,
          iconColor: Colors.blue.shade700,
          points: [
            'Pantau prakiraan cuaca (BMKG) dan peringatan dini secara berkala melalui aplikasi ini atau radio.',
            'Simpan nomor telepon darurat (Basarnas, Pemadam Kebakaran, Ambulans, BPBD) di ponsel semua anggota keluarga.',
            'Pahami jalur evakuasi di lingkungan Anda dan sepakati titik kumpul bersama keluarga.',
            'Latih seluruh anggota keluarga cara mematikan listrik dan gas sentral.',
          ],
        ),
        _buildGuideCard(
          title: '2. Tas Siaga Bencana (Evacuation Kit)',
          icon: LucideIcons.package,
          iconColor: Colors.purple.shade600,
          points: [
            'Siapkan pakaian hangat, senter ekstra, baterai cadangan, peluit, dan korek api.',
            'Bawa obat-obatan pribadi, kotak P3K, air minum kemasan (minimal untuk 3 hari), serta makanan kering instan.',
            'Pastikan power bank selalu terisi penuh untuk menjaga komunikasi tetap aktif.',
            'Siapkan perlengkapan khusus jika ada bayi, lansia, atau penyandang disabilitas di rumah.',
          ],
        ),
        _buildGuideCard(
          title: '3. Perlindungan Dokumen & Harta',
          icon: LucideIcons.folderKey,
          iconColor: Colors.indigo.shade600,
          points: [
            'Siapkan dokumen penting (ijazah, sertifikat, KK, surat lahir) dalam map plastik tahan air yang tertutup rapat.',
            'Digitalisasi dokumen (scan/foto) dan simpan di penyimpanan awan (cloud) atau flashdisk.',
            'Tempatkan barang-barang elektronik dan furnitur berharga ke lantai atas atau area yang lebih tinggi.',
          ],
        ),
        _buildGuideCard(
          title: '4. Pengamanan Lingkungan',
          icon: LucideIcons.home,
          iconColor: Colors.teal.shade700,
          points: [
            'Jaga kebersihan saluran air/parit di depan rumah agar aliran air tidak tersumbat.',
            'Siapkan karung pasir (sandbags) untuk menghalangi air masuk melalui celah pintu bawah jika berada di daerah rawan tinggi.',
          ],
        ),
      ],
    );
  }

  Widget _buildDuringTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeroBanner(
          title: 'Tanggap Darurat (Saat Banjir)',
          desc: 'Langkah taktis yang wajib diambil saat genangan air mulai masuk ke wilayah pemukiman atau rumah Anda.',
          color: Colors.red.shade700,
          icon: LucideIcons.alertOctagon,
        ),
        const SizedBox(height: 20),
        _buildGuideCard(
          title: '1. Keamanan Fisik & Evakuasi',
          icon: LucideIcons.activity,
          iconColor: Colors.red.shade600,
          points: [
            'Evakuasi diri secepatnya jika ada imbauan dari petugas BPBD/SAR atau jika air naik dengan cepat.',
            'Bawa Tas Siaga Bencana yang sudah disiapkan sebelumnya.',
            'Jangan pernah berjalan atau berkendara menerobos arus banjir (arus setinggi lutut orang dewasa sanggup menyeret Anda, dan air setinggi 60cm dapat menghanyutkan mobil).',
            'Gunakan alas kaki tertutup (sepatu bot karet) jika terpaksa harus masuk ke genangan air untuk mencegah leptospirosis dan luka akibat benda tajam.',
          ],
        ),
        _buildGuideCard(
          title: '2. Amankan Sumber Bahaya',
          icon: LucideIcons.zapOff,
          iconColor: Colors.orange.shade700,
          points: [
            'Matikan aliran listrik di dalam rumah dengan menurunkan saklar utama/sekring (MCB) segera sebelum air meninggi.',
            'Cabut regulator tabung gas elpiji dan amankan kompor ke tempat tinggi agar tidak memicu kebakaran.',
            'Jauhi saluran air bawah tanah, selokan besar, dan tiang listrik untuk menghindari terseret arus dan sengatan listrik.',
          ],
        ),
        _buildGuideCard(
          title: '3. Komunikasi & Informasi',
          icon: LucideIcons.smartphone,
          iconColor: Colors.blue.shade700,
          points: [
            'Terus pantau informasi dari aparat setempat atau melalui aplikasi siaga banjir.',
            'Gunakan telepon seluler hanya untuk keadaan darurat agar baterai tidak cepat habis.',
            'Laporkan kondisi terkini (kedalaman air) melalui aplikasi ini agar warga dan aparat terkait mengetahui situasi wilayah Anda.',
          ],
        ),
      ],
    );
  }

  Widget _buildAfterTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeroBanner(
          title: 'Pasca-Bencana (Pemulihan)',
          desc: 'Tindakan yang harus dilakukan setelah air banjir surut untuk menjaga kesehatan, keselamatan, dan kebersihan lingkungan.',
          color: Colors.green.shade700,
          icon: LucideIcons.heartPulse,
        ),
        const SizedBox(height: 20),
        _buildGuideCard(
          title: '1. Keamanan Kembali ke Rumah',
          icon: LucideIcons.shieldCheck,
          iconColor: Colors.blueGrey.shade700,
          points: [
            'Jangan langsung masuk ke rumah; periksa terlebih dahulu kerusakan struktural (dinding retak, pondasi terkikis, atap melengkung).',
            'Jangan langsung menyalakan listrik. Pastikan panel listrik, stop kontak, dan semua peralatan elektronik sudah benar-benar kering atau diperiksa oleh teknisi ahli.',
            'Nyalakan senter untuk penerangan, jangan gunakan korek api atau lilin karena gas mungkin masih bocor dan terperangkap di dalam ruangan.',
          ],
        ),
        _buildGuideCard(
          title: '2. Kebersihan & Sanitasi',
          icon: LucideIcons.droplets,
          iconColor: Colors.green.shade600,
          points: [
            'Wajib gunakan sepatu bot, sarung tangan karet tebal, dan masker saat membersihkan sisa lumpur dan puing-puing.',
            'Cuci bersih seluruh dinding, lantai, dan perabotan yang terkena air banjir menggunakan sabun cair antibakteri dan semprotkan desinfektan.',
            'Buang barang berlapis kain (seperti kasur atau sofa kapuk) yang terendam penuh karena dapat menjadi sarang jamur dan bakteri.',
          ],
        ),
        _buildGuideCard(
          title: '3. Kesehatan & Keamanan Konsumsi',
          icon: LucideIcons.apple,
          iconColor: Colors.teal.shade700,
          points: [
            'Jangan langsung mengonsumsi air sumur sebelum dikuras dan diuji kelayakannya.',
            'Selalu rebus air minum hingga benar-benar mendidih (minimal 3 menit penuh) sebelum dikonsumsi.',
            'Buang semua bahan makanan dan minuman (bahkan dalam botol/kaleng tertutup) yang sempat bersentuhan dengan genangan air banjir.',
            'Segera kunjungi posko kesehatan terdekat jika Anda atau keluarga mengalami gejala demam, diare, mual, atau gatal-gatal.',
          ],
        ),
        _buildGuideCard(
          title: '4. Waspada Hewan Liar',
          icon: LucideIcons.bug,
          iconColor: Colors.amber.shade800,
          points: [
            'Gunakan tongkat kayu panjang saat membongkar tumpukan barang atau puing basah.',
            'Waspadai ular, kalajengking, kelabang, atau tikus yang sering kali bersembunyi mencari tempat kering di dalam rumah.',
          ],
        ),
      ],
    );
  }

  Widget _buildHeroBanner({
    required String title,
    required String desc,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> points,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEFF2F6)),
            const SizedBox(height: 14),
            ...points.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
