extends Node2D

@onready var llama = $LlamaGD

var result = ""

func _ready():
   llama.load_model()
   await llama.model_loaded

   print("Model has been loaded")

   var text = "Pada bulan Juli tahun 2022 Tn. Nakila mendirikan perusahaan jasa yang diberi nama 'Perusahaan Jasa Nakula' dengan kejadian atau transaksi sebagai berikut:


Juli 2 | Tn. Nakila mengerahkan uang tunai sebesar Rp. 4.000.000,00 sebagai modal pertama
Juli 4 | Membeli perlengkapan untuk usaha secara tunai sebesar Rp. 500.000,00
Juli 6 | Membeli peralatan untuk usaha seharga Rp. 1.600.000,00, tetapi baru dibayar Rp. 600.000,00
Juli 8 | Membeli Kembali perlengkapan seharga Rp. 600.000,00, namun baru dibayar tunai Rp. 2000.000,00
Juli 10 | Diselesaikan pekerjaan jasa pada suatu perusahaan sebesar Rp 600.000,00
Juli 12 | Diselesaikan pekerjaan jasa kepada pelanggan senilai Rp. 1.000.000,00
Juli 14 | Membayar upah tenaga kerja sebesar Rp. 200.000,00
Juli 15 | Melunasi utang atas pembelian peralatan tanggal 6 juli
Juli 20 | Membayar rekening listrik dan air sebesar Rp. 60.000,00
Juli 22 | Menyelesaikan pekerjaan senilai Rp. 700.000,00. tetapi baru diterima tunai senilai Rp. 400.000,00, sisanya dikemudian ari
Juli 24 | Menerima piutang atas transaksi tanggal 12 Juli
Juli 26 | Dibayar sewa tempat untuk Bulan Juli senilai Rp. 50.000,00
Juli 28 | Tn. Nakula mengambil uang perusahaan untuk keperluan pribadi sebesar Rp. 100.000,00
Juli 29 | Perlengkapan yang dipakar sebesar Rp. 250.000,00
Juli 30 | Perlengkapan yang terpakai sebesar Rp. 50.000,00
"

   var prompt = "\n".join([
      "<|system|>",
      "You are a helpful assistant that answers concisely which speaks Indonesian.<|end|>",
      "<|user|>",
      "Please summarize the text below into a table with the columns: Date of transaction, Name of transaction, Transaction Amount, Additional Description",
      "```text",
      "%s",
      "```",
      "<|assistant|>",
      ""
   ]) % text

   llama.new_token_generated.connect(concat_print)
   llama.create_completion_async(prompt)
   await llama.generation_completed

func concat_print(token):
   result += token
   print(result)