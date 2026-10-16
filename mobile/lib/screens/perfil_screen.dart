import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cliente_api.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import '../widgets/avatar_cliente.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _carregando = true;
  bool _enviandoFoto = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      await ClienteSessionScope.of(context).carregarResumo();
    } catch (_) {
      // Tela continua usável mesmo se o resumo falhar ao carregar.
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// JPEG ou PNG pelos bytes iniciais (é o que a API aceita).
  String? _tipoDaImagem(Uint8List b) {
    if (b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e && b[3] == 0x47) return 'image/png';
    if (b.length > 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) return 'image/jpeg';
    return null;
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    final messenger = ScaffoldMessenger.of(context);
    final session = ClienteSessionScope.of(context);
    try {
      // Reduz na origem: foto de câmera tem vários MB e o avatar é pequeno.
      final arquivo = await _picker.pickImage(source: origem, maxWidth: 640, maxHeight: 640, imageQuality: 85);
      if (arquivo == null) return; // cancelou
      final bytes = await arquivo.readAsBytes();
      final tipo = _tipoDaImagem(bytes);
      if (tipo == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Formato não suportado. Use uma foto JPG ou PNG.')));
        return;
      }
      if (!mounted) return;
      setState(() => _enviandoFoto = true);
      await session.trocarFoto(bytes, tipo);
      messenger.showSnackBar(const SnackBar(content: Text('Foto atualizada!')));
    } on ClienteApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensagem)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Não foi possível atualizar a foto. Tente novamente.')));
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  Future<void> _removerFoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final session = ClienteSessionScope.of(context);
    setState(() => _enviandoFoto = true);
    try {
      await session.removerFoto();
      messenger.showSnackBar(const SnackBar(content: Text('Foto removida.')));
    } on ClienteApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensagem)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Não foi possível remover a foto.')));
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  void _abrirOpcoesFoto(bool temFoto) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.of(ctx).pop();
                _escolherFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.of(ctx).pop();
                _escolherFoto(ImageSource.gallery);
              },
            ),
            if (temFoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remover foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _removerFoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _sair(BuildContext context) {
    ClienteSessionScope.of(context).logout();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final session = ClienteSessionScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([theme, session]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _carregar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meu Perfil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textDark)),
                        const SizedBox(height: 18),
                        _buildProfileCard(theme, session),
                        const SizedBox(height: 18),
                        _buildStatsRow(theme, session),
                        const SizedBox(height: 24),
                        _buildLogoutButton(theme, context),
                      ],
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(ThemeProvider theme, ClienteSession session) {
    final nome = (session.cliente?['nome'] as String?) ?? '';
    final contato = (session.cliente?['email'] as String?) ?? (session.cliente?['telefone'] as String? ?? '');
    final fotoUrl = session.cliente?['foto_url'] as String?;
    final temFoto = fotoUrl != null && fotoUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.primary, theme.primaryDark]),
        boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          // Toque no avatar para trocar a foto (câmera ou galeria).
          GestureDetector(
            onTap: _enviandoFoto ? null : () => _abrirOpcoesFoto(temFoto),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarCliente(
                  fotoUrl: fotoUrl,
                  nome: nome,
                  tamanho: 76,
                  fundo: theme.cardBg,
                  corTexto: theme.primary,
                  borda: theme.cardBg,
                ),
                if (_enviandoFoto)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
                      child: const Center(
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)),
                      ),
                    ),
                  ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: theme.accent, shape: BoxShape.circle, border: Border.all(color: theme.cardBg, width: 2)),
                    child: const Icon(Icons.photo_camera, size: 14, color: Color(0xFF1A1A1A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(contato, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeProvider theme, ClienteSession session) {
    final resumo = session.resumo;
    final stats = [
      _StatData('${resumo?['saldoTotal'] ?? 0}', 'Saldo', Icons.star_rounded),
      _StatData('${resumo?['totalMarcacoes'] ?? 0}', 'Marcações', Icons.bookmark_outline),
      _StatData('${resumo?['totalResgates'] ?? 0}', 'Resgates', Icons.card_giftcard),
    ];
    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: s == stats.last ? 0 : 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Icon(s.icon, color: theme.primary, size: 22),
                      const SizedBox(height: 6),
                      Text(s.value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textDark)),
                      const SizedBox(height: 2),
                      Text(s.label, style: TextStyle(fontSize: 11, color: theme.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLogoutButton(ThemeProvider theme, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _sair(context),
        icon: const Icon(Icons.logout, size: 18, color: Colors.red),
        label: const Text('Sair da conta', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCC8C8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: theme.cardBg,
        ),
      ),
    );
  }
}

class _StatData {
  final String value;
  final String label;
  final IconData icon;
  const _StatData(this.value, this.label, this.icon);
}
