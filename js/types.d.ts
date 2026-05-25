/** @file Baseline domain types for LostNumber (TypeScript-light / JSDoc). */

interface LNPosition {
  x: number;
  y: number;
}

interface LNCell {
  number: number | null;
  merged: boolean;
  frozen: boolean;
  freezeTurns: number;
  freezeMaxTurns: number;
  freezeType?: string | null;
}

/** In-memory grid: column-major `grid[x][y]`. */
type LNGrid = LNCell[][];

interface LNLevelConfig {
  target: number;
  numbers: number[];
  newNumbers: number[];
}

interface LNBonusInventory {
  destroy: number;
  shuffle: number;
  explosion: number;
}

interface LNSerializedGridCell {
  value: number | null;
  merged: boolean;
  frozen: boolean;
  freezeTurns: number;
  freezeMaxTurns: number;
  freezeType?: string | null;
}

interface LNSaveData {
  version?: number;
  gridSchemaVersion?: number;
  currentLevel?: number;
  xp?: number;
  xpMultiplier?: number;
  xpMultiplierTurns?: number;
  grid?: unknown;
  bonusInventory?: Partial<LNBonusInventory>;
  pendingTransition?: LNPendingTransition | null;
  maxReachedNumber?: number;
  carryNumber?: number | null;
  frozenCells?: Record<string, number | { turns?: number }>;
  stats?: Record<string, unknown>;
  achievements?: Record<string, unknown>;
  wheelSpinsToday?: number;
  lastWheelDay?: string;
}

interface LNPendingTransition {
  active?: boolean;
  nextLevel?: number;
  carryNumber?: number | null;
}

interface LNDailyQuest {
  id: string;
  textKey: string;
  rewardKey: string;
}

interface LNDailyQuestsBundle {
  date: string;
  completed: Record<string, boolean>;
  list: LNDailyQuest[];
}

interface LNMoveValidationResult {
  valid: boolean;
  reason?: string;
}

interface LNMoveValidationState {
  selected: LNPosition[];
  grid: LNGrid;
  chain: {
    numbers: number[];
    sum: number;
  };
  frozenCells?: Map<number, unknown>;
}

type LNBonusType = 'destroy' | 'shuffle' | 'explosion';

/** JSDoc aliases (existing @ts-check annotations). */
type GridPoint = LNPosition;
type LostNumberCell = LNCell;
type LevelConfig = LNLevelConfig;
type BonusInventory = LNBonusInventory;
type BonusType = LNBonusType;
type SerializedGridCell = LNSerializedGridCell;
type SaveData = LNSaveData;
type PendingTransition = LNPendingTransition;
type MoveValidationState = LNMoveValidationState;
type MoveValidationResult = LNMoveValidationResult;

/** Runtime globals from index.html script tags (loose until fully typed). */
declare const ErrorHandler: any;
declare const Rules: any;
declare const Chain: any;

/** Merge with JS `class` — index signature for prototype extensions and state proxy fields. */
interface StorageManager {
  [key: string]: any;
}

interface GridManager {
  [key: string]: any;
}

interface LostNumberGame {
  [key: string]: any;
}
