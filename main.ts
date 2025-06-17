import { Bot, InlineKeyboard, Context } from "./deps.ts";

const BOT_TOKEN = Deno.env.get("BOT_TOKEN")!;
const GROUP_ADMIN_ID = Number(Deno.env.get("GROUP_ADMIN_ID")!); // contoh: -1001234567890

const bot = new Bot(BOT_TOKEN);

interface UserReg {
  id: number;
  fullname: string;
  username: string;
  email: string;
  approved: boolean;
}

// In-memory, ganti persistent storage jika ingin survive restart
const sessions: Record<number, { step: string; [k: string]: unknown }> = {};
const registeredUsers: Record<number, UserReg> = {};

function isRegistered(id: number) {
  return registeredUsers[id]?.approved;
}

// --- Start/Menu Handler
bot.command(["start", "menu"], async (ctx) => {
  const id = ctx.from?.id;
  if (!id) return;
  if (!registeredUsers[id]) {
    sessions[id] = { step: "reg_fullname" };
    await ctx.reply("📝 *Pendaftaran User Baru*\n\nMasukkan nama lengkap kamu:", { parse_mode: "Markdown" });
    return;
  }
  if (!registeredUsers[id].approved) {
    await ctx.reply("⏳ Permohonan kamu menunggu persetujuan admin.");
    return;
  }
  sendMainMenu(ctx, "Pilih fitur utama:");
});

// --- Register User
bot.on("message:text", async (ctx) => {
  const id = ctx.from?.id;
  if (!id) return;
  if (isRegistered(id)) return;
  const session = sessions[id];
  if (!session || typeof ctx.message.text !== "string") return;

  if (session.step === "reg_fullname") {
    session.fullname = ctx.message.text.trim();
    session.step = "reg_email";
    await ctx.reply("📧 Masukkan email aktif kamu:");
  } else if (session.step === "reg_email") {
    session.email = ctx.message.text.trim();
    session.step = "reg_reason";
    await ctx.reply("💬 Jelaskan alasan mendaftar:");
  } else if (session.step === "reg_reason") {
    session.reason = ctx.message.text.trim();
    registeredUsers[id] = {
      id,
      fullname: session.fullname as string,
      username: ctx.from?.username || "-",
      email: session.email as string,
      approved: false,
    };
    await sendRegistrationToGroup(ctx, registeredUsers[id], session.reason as string);
    await ctx.reply("✅ Permohonan pendaftaran kamu sudah dikirim ke admin. Tunggu persetujuan.");
    delete sessions[id];
  }
});

// --- Callback Query untuk Approval
bot.on("callback_query:data", async (ctx) => {
  const id = ctx.from.id;
  // Hanya admin group yang bisa approve/reject
  if (ctx.chat?.id === GROUP_ADMIN_ID) {
    if (ctx.callbackQuery.data?.startsWith("approve_")) {
      const userId = Number(ctx.callbackQuery.data.replace("approve_", ""));
      if (registeredUsers[userId]) {
        registeredUsers[userId].approved = true;
        await ctx.api.sendMessage(userId, "✅ Permohonan kamu disetujui! /menu untuk mulai.");
        await ctx.editMessageReplyMarkup({ inline_keyboard: [] });
        await ctx.reply(`✅ User <a href="tg://user?id=${userId}">${registeredUsers[userId].fullname}</a> sudah disetujui.`, { parse_mode: "HTML" });
      }
    } else if (ctx.callbackQuery.data?.startsWith("reject_")) {
      const userId = Number(ctx.callbackQuery.data.replace("reject_", ""));
      if (registeredUsers[userId]) {
        await ctx.api.sendMessage(userId, "❌ Maaf, permohonan kamu ditolak.");
        delete registeredUsers[userId];
        await ctx.editMessageReplyMarkup({ inline_keyboard: [] });
        await ctx.reply(`❌ User <a href="tg://user?id=${userId}">${userId}</a> ditolak.`, { parse_mode: "HTML" });
      }
    }
    await ctx.answerCallbackQuery();
    return;
  }

  // Non-admin: cek sudah approve atau belum
  if (!isRegistered(id)) {
    if (!registeredUsers[id]) {
      sessions[id] = { step: "reg_fullname" };
      await ctx.reply("📝 *Pendaftaran User Baru*\n\nMasukkan nama lengkap kamu:", { parse_mode: "Markdown" });
    } else {
      await ctx.reply("⏳ Permohonan kamu sedang menunggu persetujuan admin.");
    }
    await ctx.answerCallbackQuery();
    return;
  }

  // Menu utama lain (contoh, bisa dikembangkan)
  if (ctx.callbackQuery.data === "menu_utama") {
    sendMainMenu(ctx, "Menu utama:");
    await ctx.answerCallbackQuery();
  }
});

// --- Fungsi Kirim Permohonan Daftar ke Grup
async function sendRegistrationToGroup(ctx: Context, user: UserReg, reason: string) {
  const msg =
    `📝 *Permohonan Daftar User Baru*\n\n` +
    `👤 Nama: ${user.fullname}\n` +
    `🔗 Username: @${user.username}\n` +
    `📧 Email: ${user.email}\n` +
    `💬 Permohonan: ${reason}\n` +
    `🆔 ID Telegram: <code>${user.id}</code>`;
  const keyboard = new InlineKeyboard()
    .text("✅ Setuju", `approve_${user.id}`)
    .text("❌ Tolak", `reject_${user.id}`);
  await ctx.api.sendMessage(GROUP_ADMIN_ID, msg, {
    parse_mode: "Markdown",
    reply_markup: keyboard,
  });
}

// --- Menu Utama (bisa dikembangkan)
function sendMainMenu(ctx: Context, desc: string) {
  const keyboard = new InlineKeyboard()
    .text("🚀 Deploy GitHub", "menu_utama");
  ctx.reply(desc, { reply_markup: keyboard });
}

// --- Jalankan bot (untuk Deno Deploy: export default)
if (import.meta.main) {
  bot.start();
}
export default bot;
