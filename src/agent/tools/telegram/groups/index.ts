import { telegramGetMeTool, telegramGetMeExecutor } from "./get-me.js";
import {
  telegramGetParticipantsTool,
  telegramGetParticipantsExecutor,
} from "./get-participants.js";
import {
  telegramKickUserTool,
  telegramKickUserExecutor,
  telegramBanUserTool,
  telegramBanUserExecutor,
  telegramUnbanUserTool,
  telegramUnbanUserExecutor,
} from "./moderation.js";
import { telegramCreateGroupTool, telegramCreateGroupExecutor } from "./create-group.js";
import { telegramSetChatPhotoTool, telegramSetChatPhotoExecutor } from "./set-chat-photo.js";
import type { ToolEntry } from "../../types.js";

export { telegramGetMeTool, telegramGetMeExecutor };
export { telegramGetParticipantsTool, telegramGetParticipantsExecutor };
export {
  telegramKickUserTool,
  telegramKickUserExecutor,
  telegramBanUserTool,
  telegramBanUserExecutor,
  telegramUnbanUserTool,
  telegramUnbanUserExecutor,
};
export { telegramCreateGroupTool, telegramCreateGroupExecutor };
export { telegramSetChatPhotoTool, telegramSetChatPhotoExecutor };

export const tools: ToolEntry[] = [
  { tool: telegramGetMeTool, executor: telegramGetMeExecutor },
  { tool: telegramGetParticipantsTool, executor: telegramGetParticipantsExecutor },
  // Disabled: kick, ban, unban, create_group, set_chat_photo (5 tools)
];
