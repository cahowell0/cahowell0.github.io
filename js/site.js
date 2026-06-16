// Cookie consent — re-shows after 90 seconds
function acceptCookies() {
  document.getElementById("cookieConsent").style.display = "none";
  setTimeout(() => {
    document.getElementById("cookieConsent").style.display = "block";
  }, 90000);
}

function rejectCookies() {
  document.getElementById("cookieConsent").style.display = "none";
  setTimeout(() => {
    document.getElementById("cookieConsent").style.display = "block";
  }, 90000);
}

// Newsletter popup — triggers at 33% scroll depth
let popupShown = false;

window.addEventListener("scroll", () => {
  if (popupShown) return;
  const scrollableHeight = document.documentElement.scrollHeight - window.innerHeight;
  const scrollPercentage = (window.scrollY / scrollableHeight) * 100;
  if (scrollPercentage >= 33) {
    document.getElementById("newsletterPopup").style.display = "flex";
    popupShown = true;
    requestAnimationFrame(() => {
      const card = document.querySelector("#newsletterPopup .popup-content");
      const span = document.getElementById("newsletterPopupSize");
      if (card && span) {
        const rect = card.getBoundingClientRect();
        span.textContent = Math.round(rect.width) + " × " + Math.round(rect.height) + " pixels";
      }
    });
  }
});

function closeNewsletterPopup() {
  document.getElementById("newsletterPopup").style.display = "none";
}

// Exit intent popup — triggers when cursor enters top 10% of viewport
let exitIntentShown = false;

document.addEventListener("mousemove", (e) => {
  if (!exitIntentShown && e.clientY < window.innerHeight * 0.1) {
    document.getElementById("exitIntentPopup").style.display = "flex";
    exitIntentShown = true;
  }
});

function closeExitIntentPopup() {
  document.getElementById("exitIntentPopup").style.display = "none";
}

// Chatbot suggestion bubbles — cycle every 5 seconds
function cycleChatbotBubbles() {
  const bubbles = [
    ["suggestionBubble1", "bubble1Size"],
    ["suggestionBubble2", "bubble2Size"],
    ["suggestionBubble3", "bubble3Size"],
  ];

  setTimeout(() => {
    const el = document.getElementById(bubbles[0][0]);
    el.style.display = "block";
    const span = document.getElementById(bubbles[0][1]);
    if (span) {
      const rect = el.getBoundingClientRect();
      span.textContent = Math.round(rect.width) + " × " + Math.round(rect.height) + " pixels";
    }
  }, 5000);

  setTimeout(() => {
    document.getElementById(bubbles[0][0]).style.display = "none";
    const el = document.getElementById(bubbles[1][0]);
    el.style.display = "block";
    const span = document.getElementById(bubbles[1][1]);
    if (span) {
      const rect = el.getBoundingClientRect();
      span.textContent = Math.round(rect.width) + " × " + Math.round(rect.height) + " pixels";
    }
  }, 10000);

  setTimeout(() => {
    document.getElementById(bubbles[1][0]).style.display = "none";
    const el = document.getElementById(bubbles[2][0]);
    el.style.display = "block";
    const span = document.getElementById(bubbles[2][1]);
    if (span) {
      const rect = el.getBoundingClientRect();
      span.textContent = Math.round(rect.width) + " × " + Math.round(rect.height) + " pixels";
    }
  }, 15000);

  setTimeout(() => {
    document.getElementById(bubbles[2][0]).style.display = "none";
    cycleChatbotBubbles();
  }, 20000);
}

cycleChatbotBubbles();

// Chatbot window
function toggleChatbot() {
  const chatbotEl = document.getElementById("chatbotWindow");
  const bubble1 = document.getElementById("suggestionBubble1");
  const bubble2 = document.getElementById("suggestionBubble2");
  const bubble3 = document.getElementById("suggestionBubble3");

  if (chatbotEl.style.display === "none") {
    bubble1.style.display = "none";
    bubble2.style.display = "none";
    bubble3.style.display = "none";
  }

  chatbotEl.style.display = chatbotEl.style.display === "none" ? "flex" : "none";

  if (chatbotEl.style.display === "flex") {
    requestAnimationFrame(() => {
      const span = document.getElementById("chatWindowSize");
      if (span) {
        const rect = chatbotEl.getBoundingClientRect();
        span.textContent = Math.round(rect.width) + " × " + Math.round(rect.height) + " pixels";
      }
    });
  }
}

function closeChatbot() {
  document.getElementById("chatbotWindow").style.display = "none";
}

function handleChatInput(event) {
  if (event.key === "Enter") sendMessage();
}

function sendMessage() {
  const input = document.getElementById("chatInput");
  const message = input.value.trim();
  if (!message) return;

  const messagesContainer = document.getElementById("chatbotMessages");

  const userMessage = document.createElement("div");
  userMessage.className = "user-message";
  userMessage.textContent = message;
  messagesContainer.appendChild(userMessage);
  messagesContainer.scrollTo({ top: messagesContainer.scrollHeight, behavior: "smooth" });

  input.value = "";

  setTimeout(() => {
    const botMessage = document.createElement("div");
    botMessage.className = "bot-message";
    botMessage.textContent =
      "I can't help with that. You can try to ask something else and I'll give you an irrelevant stock reply.";
    messagesContainer.appendChild(botMessage);
    messagesContainer.scrollTo({ top: messagesContainer.scrollHeight, behavior: "smooth" });
  }, 1000);
}

// Clear all email inputs on every page load (safe to run immediately since defer ensures DOM is ready)
document.querySelectorAll("input[type='email']").forEach((el) => (el.value = ""));
